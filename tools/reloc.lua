-- MAME autoboot script for tools/reloc.py. Do not run it directly: reloc.py puts a CFG
-- table in front of it. Every CFG.every frames it appends the screen's pixels to
-- CFG.out, and plays the input events in CFG.events, as tools/trace.lua does. Each change of
-- ROUND_MAIN goes in CFG.rounds as "frame value", to show which rounds the run really played.
-- With CFG.special, each time the item shows and goes, "shown gone taker" go in CFG.items: two
-- frames, then P1, P2 or none. With CFG.reads, each ROM address the main CPU reads as data goes in
-- that file once for each instruction that reads it, as "page,addr,pc" (tools/romreads.lua).

local machine = manager.machine

-- MAME reruns this script on each reset, in the same Lua state. A run has no reset in it, so the
-- second time here means the game crashed or its watchdog fired.
if RELOC_FRAME then
  assert(io.open(CFG.reset, "w")):close()
  machine:exit()
  return
end

local frame = 0
local ev = 1
local out = assert(io.open(CFG.out, "wb"))
local rounds = assert(io.open(CFG.rounds, "w"))
local space = machine.devices[":maincpu"].spaces["program"]
local round = nil
local items = CFG.special and CFG.special > 0 and assert(io.open(CFG.items, "w"))
local shown = nil  -- the frame the special item appeared on
local taker = nil  -- who took it: IX+9 as it was stored, 0 or 1

-- Keep the taps referenced. SPECIAL_TAKE writes the player to F460. INVINCIBLE_ITEM_TAKE, for kind
-- 0E's own item, does not, but it has the player's record in IX as it writes F518 = 1.
if items then
  RELOC_TAKER = space:install_write_tap(0xF460, 0xF460, "reloc_taker",
    function(offset, data, mask) taker = data end)
  RELOC_TAKER_0E = space:install_write_tap(0xF518, 0xF518, "reloc_taker_0e",
    function(offset, data, mask)
      if data == 1 then taker = space:read_u8(machine.devices[":maincpu"].state["IX"].value + 9) end
    end)
end

local reads = {}
if CFG.reads then
  local curpc = machine.devices[":maincpu"].state["CURPC"]
  local page = 0
  RELOC_READS = {
    space:install_read_tap(0x0000, 0xBFFF, "reloc_reads", function(offset, data, mask)
      local pc = curpc.value
      if (offset - pc) & 0xFFFF >= 4 then  -- not the instruction's own bytes
        reads[(page << 32) | (offset << 16) | pc] = true
      end
    end),
    space:install_write_tap(0xFB40, 0xFB40, "reloc_bank", function(offset, data, mask)
      page = (data ~ 4) & 7
    end),
  }
end

local dump = nil  -- CFG.dump: object and game RAM (DD00-DFFF, E000-F7FF) on each frame of a range

-- gfx_num BA-BF and FA-FF make MAME's renderer read past the end of its 0x1D00 bytes of video RAM,
-- into whatever is next on its heap, so such a picture is not the machine's. Only the RAM test puts
-- them in object RAM. A sample with one holds what the screen is drawn from instead: video, object
-- and palette RAM, then zeros to the size of a picture (notes/relocation.md).
local PADDING = string.rep("\0", 256 * 224 * 4 - 0x2200)
local function video_ram()
  return space:read_range(0xC000, 0xDFFF, 8) .. space:read_range(0xF800, 0xF9FF, 8) .. PADDING
end

local function drawn_from_ram()
  for a = 0xDD01, 0xDFFD, 4 do
    local gfx = space:read_u8(a)
    if gfx & 0xA0 == 0xA0 and gfx & 0x1F >= 0x1A then return false end
  end
  return true
end

local function field(port, name)
  local p = machine.ioport.ports[port]
  local f = p and p.fields[name]
  if not f then error("no input " .. port .. " / " .. name) end
  return f
end

RELOC_FRAME = emu.add_machine_frame_notifier(function()
  frame = frame + 1
  local now = space:read_u8(0xE64B)
  if now ~= round then
    round = now
    rounds:write(frame, " ", now, "\n")
  end
  if items then
    local up = space:read_u8(0xF45F) & 1 ~= 0 or (CFG.special == 0x0E and space:read_u8(0xF514) & 1 ~= 0)
    if up and not shown then
      shown = frame
      taker = nil
    elseif shown and not up then
      items:write(shown, " ", frame, " ", taker and "P" .. (taker + 1) or "none", "\n")
      shown = nil
    end
  end
  if CFG.dump and frame >= CFG.dump_from and frame <= CFG.dump_to then
    dump = dump or assert(io.open(CFG.dump, "wb"))
    dump:write(space:read_range(0xDD00, 0xDFFF, 8), space:read_range(0xE000, 0xF7FF, 8))
  end
  if frame % CFG.every == 0 then
    out:write(drawn_from_ram() and (machine.screens[":screen"]:pixels()) or video_ram())  -- pixels() also returns the size
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
  if frame >= CFG.frames then
    out:close()
    rounds:close()
    if items then items:close() end
    if dump then dump:close() end
    if CFG.reads then
      local f = assert(io.open(CFG.reads, "w"))
      for key in pairs(reads) do
        f:write(string.format("%d,%04X,%04X\n", key >> 32, (key >> 16) & 0xFFFF, key & 0xFFFF))
      end
      f:close()
    end
    machine:exit()
  end
end)
