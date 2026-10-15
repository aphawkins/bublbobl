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
          if offset & 0xFFC0 == 0xFB40 then
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
