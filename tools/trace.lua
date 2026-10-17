-- MAME autoboot script for tools/trace.py. Do not run it directly: trace.py puts a
-- CFG table in front of it. Needs mame -debug (any -debugger, "none" for headless).
--
-- Every CFG.chunk frames the debugger trace of each CPU moves to a new file
-- (<cpu>_<n>.log), so trace.py can read and delete the finished ones while MAME runs.
-- The main CPU's trace has a line "B<xx>" after each write to the bank latch FB40.
--
-- Memory taps record which instruction (CURPC, plus the bank for 8000-BFFF) reads and
-- writes each RAM and I/O address. Writes to the sound latch FA00 are logged in order.

local machine = manager.machine
local dbg = machine.debugger
local out = CFG.out

local function devtag(name) return ":" .. name end

-- Main CPU bank: file page 0-3 of a78-05-1, from the last write to FB40 (data ^ 4) & 7.
local bank = -1
local bank_raw = nil

-- Access counts: key = addr * 2^24 + kind * 2^20 + pcid, where pcid = pc, or
-- pc + 0x10000 * (page + 1) for main CPU code in the bank window.
local counts = {}
TRACE_HANDLERS = {}  -- taps live while referenced
local handlers = TRACE_HANDLERS
local sound_log = {}
local frame = 0

local muted = false  -- true while the script itself reads memory

local function pcid(cpu, pc)
  if cpu.main and pc >= 0x8000 and pc < 0xC000 then
    return pc + 0x10000 * (bank + 1)
  end
  return pc
end

-- "1A2B", or "bank2:9C40" for main CPU code in the bank window ("bank?:" before any write).
local function pcstr(id)
  if id >= 0x10000 then
    local page = id // 0x10000 - 1
    return (page >= 0 and ("bank" .. page) or "bank?") .. string.format(":%04X", id % 0x10000)
  end
  return string.format("%04X", id)
end

for i, c in ipairs(CFG.cpus) do
  local dev = machine.devices[devtag(c.tag)]
  c.dev = dev
  c.curpc = dev.state["CURPC"]
  c.space = dev.spaces["program"]
  c.index = i
end

local function count(c, kind, addr)
  if muted then return end
  local key = (c.index * 0x10000 + addr) * 0x1000000 + kind * 0x100000 + pcid(c, c.curpc.value)
  counts[key] = (counts[key] or 0) + 1
end

-- Sprite draws: every 16 x 16 sprite goes through SPRITE (147D) or SPRITE_FLIPX (149C),
-- whose first tile write is at 1480 or 14A1. There B = first tile, C = tile attribute and
-- IY = the sprite's quarter of a gfx block. The caller is the return address on the stack,
-- or one level further out for the list helpers that loop over SPRITE. The object's tile
-- bank is read from the object RAM copy (OBJ_SHADOW, E1CD) when the frame is shown,
-- that is, when the IRQ handler starts copying it to DD00. IX is logged too: most callers
-- point it at the record of the thing being drawn, so it says whose frame it is.
local SPRITE_FIRST_WRITE = { [0x1480] = "n", [0x14A1] = "x" }
local LIST_RETURNS = { [0x14DA] = 8, [0x14FE] = 8, [0x150F] = 6, [0x1521] = 6 }
local sprite_counts = {}  -- "caller,flip,gfx,bank,tile,attr,ix" -> { n, first frame }
local pending = {}        -- this frame's draws: { caller, flip, gfx, tile, attr, ix }

local function word(space, addr)
  return space:read_u8(addr) | (space:read_u8((addr + 1) & 0xFFFF) << 8)
end

-- "1A2B", or "bank2:9C40" from the bank bits in FB40_COPY (E1CB), which the code writes
-- alongside FB40 itself.
local function code_addr(space, addr)
  if addr >= 0x8000 and addr < 0xC000 then
    local page = (space:read_u8(0xE1CB) ~ 4) & 7
    return (page <= 3 and ("bank" .. page) or "bank?") .. string.format(":%04X", addr)
  end
  return string.format("%04X", addr)
end

local function sprite_draw(c, pc)
  local st = c.dev.state
  local sp = st["SP"].value
  muted = true
  local ret = word(c.space, sp)
  local caller = ret
  if LIST_RETURNS[ret] then caller = word(c.space, sp + LIST_RETURNS[ret]) end
  local where = code_addr(c.space, caller - 3)
  muted = false
  local iy = st["IY"].value - 0xC000
  local gfx = (iy // 0x80) | (((iy % 0x80) // 0x10) << 5)
  pending[#pending + 1] = { where, SPRITE_FIRST_WRITE[pc], gfx, st["B"].value, st["C"].value,
    st["IX"].value }
end

local function sprites_shown(c)
  if #pending == 0 then return end
  muted = true
  local banks = {}
  for n = 0, 0x168 // 4 - 1 do
    local o = 0xE1CD + n * 4
    local g = c.space:read_u8(o + 1)
    if banks[g] == nil and (c.space:read_u8(o) | g | c.space:read_u8(o + 2)) ~= 0 then
      banks[g] = c.space:read_u8(o + 3) & 0x0F
    end
  end
  muted = false
  for _, d in ipairs(pending) do
    local bank = banks[d[3]]
    local key = string.format("%s,%s,%02X,%s,%02X,%02X,%04X", d[1], d[2], d[3],
      bank and string.format("%X", bank) or "-", d[4], d[5], d[6])
    local s = sprite_counts[key]
    if s then s[1] = s[1] + 1 else sprite_counts[key] = { 1, frame } end
  end
  pending = {}
end

for _, c in ipairs(CFG.cpus) do
  for _, r in ipairs(c.taps or {}) do
    local lo, hi = r[1], r[2]
    if CFG.reads then
      handlers[#handlers + 1] = c.space:install_read_tap(lo, hi, "trace_r_" .. c.tag,
        function(offset, data, mask) count(c, 0, offset) end)
    end
    handlers[#handlers + 1] = c.space:install_write_tap(lo, hi, "trace_w_" .. c.tag,
      function(offset, data, mask)
        count(c, 1, offset)
        if c.main then
          if offset < 0xD000 then
            local pc = c.curpc.value
            if SPRITE_FIRST_WRITE[pc] then sprite_draw(c, pc) end
          elseif offset == 0xDD00 and c.curpc.value == 0x04B6 then
            sprites_shown(c)
          elseif offset & 0xFFC0 == 0xFB40 then
            bank = (data ~ 4) & 7
            bank_raw = data
          elseif offset & 0xFF83 == 0xFA00 then
            sound_log[#sound_log + 1] = string.format("%d,%s,%02X", frame,
              pcstr(pcid(c, c.curpc.value)), data)
          end
        end
      end)
  end
end

-- Inputs: CFG.events = { {f=frame, port=":IN1", field="P1 Left", v=1}, ... } in frame order.
-- v is the logical state (1 = pressed). DIP switches come from the cfg file trace.py writes.
local ev = 1
local function field(port, name)
  local p = machine.ioport.ports[port]
  local f = p and p.fields[name]
  if not f then error("no input " .. port .. " / " .. name) end
  return f
end

local chunk = 0
local tracing = false
local function trace_on()
  for _, c in ipairs(CFG.cpus) do
    if c.trace then
      dbg:command(string.format("trace %s/%s_%05d.log,%s", out, c.name, chunk, c.tag))
    end
  end
  tracing = true
  -- Restate the bank at the top of each file, so each one can be read on its own.
  if bank_raw then dbg:command(string.format("tracelog \"B%02X\\n\"", bank_raw)) end
end
local function trace_off()
  for _, c in ipairs(CFG.cpus) do
    if c.trace then dbg:command("trace off," .. c.tag) end
  end
  tracing = false
end

local function finish()
  if tracing then trace_off() end
  local f = assert(io.open(out .. "/access.csv", "w"))
  f:write("cpu,addr,kind,pc,count\n")
  local kinds = { [0] = "R", [1] = "W" }
  for key, n in pairs(counts) do
    local id = key // 0x1000000
    local rest = key % 0x1000000
    local c = CFG.cpus[id // 0x10000]
    local where = pcstr(rest % 0x100000)
    f:write(string.format("%s,%04X,%s,%s,%d\n", c.name, id % 0x10000, kinds[rest // 0x100000], where, n))
  end
  f:close()
  f = assert(io.open(out .. "/sound.csv", "w"))
  f:write("frame,pc,cmd\n")
  for _, line in ipairs(sound_log) do f:write(line, "\n") end
  f:close()
  f = assert(io.open(out .. "/sprites.csv", "w"))
  f:write("caller,flip,gfx,bank,tile,attr,ix,count,first_frame\n")
  for key, s in pairs(sprite_counts) do f:write(string.format("%s,%d,%d\n", key, s[1], s[2])) end
  f:close()
  f = assert(io.open(out .. "/done", "w"))
  f:write(tostring(frame), "\n")
  f:close()
end

-- The bank marker goes into the visible CPU's trace, which is the main CPU at boot.
-- (Not "focus": that stops the debugger from seeing the other CPUs at all.)
dbg:command("wpset fb40:maincpu,40,w,1,{tracelog \"B%02X\\n\",wpdata; g}")

-- Keep the subscriptions referenced: the garbage collector would cancel them.
TRACE_FRAME_SUB = emu.add_machine_frame_notifier(function()
  frame = frame + 1
  if frame % 60 == 0 then
    local f = io.open(out .. "/progress", "w")
    if f then f:write(tostring(frame), "\n"); f:close() end
  end
  -- Snapshots: a screenshot and the main CPU's RAM (C000-FFFF) every CFG.snap frames.
  if CFG.snap > 0 and frame % CFG.snap == 0 then
    machine.video:snapshot()
    local f = io.open(string.format("%s/snap/ram_%06d.bin", out, frame), "wb")
    if f then
      muted = true
      f:write(CFG.cpus[1].space:read_range(0xC000, 0xFFFF, 8))
      muted = false
      f:close()
    end
  end
  while CFG.events[ev] and CFG.events[ev].f <= frame do
    local e = CFG.events[ev]
    if e.v ~= 0 then
      field(e.port, e.field):set_value(1)
    else
      field(e.port, e.field):clear_value()
    end
    ev = ev + 1
  end
  if frame == CFG.start then
    trace_on()
  elseif tracing and (frame - CFG.start) % CFG.chunk == 0 then
    trace_off()
    chunk = chunk + 1
    trace_on()
  end
  if CFG.frames > 0 and frame >= CFG.frames then
    finish()
    machine:exit()
  end
end)

TRACE_STOP_SUB =emu.add_machine_stop_notifier(function()
  local f = io.open(out .. "/done", "r")
  if f then f:close() else finish() end
end)

dbg.execution_state = "run"
