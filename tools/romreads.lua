-- MAME autoboot script for tools/romreads.py. Do not run it directly: romreads.py puts a CFG
-- table and tools/cheats.lua in front of it. It plays CFG.events and writes CFG.reads_out: one
-- line "page,addr,pc" for each ROM address the main CPU reads as data, by each instruction.
-- page is the bank page (0-3) in the window at 8000-BFFF, and - below 8000.

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local space = cpu.spaces["program"]
local curpc = cpu.state["CURPC"]
local page = 0
local seen = {}
local frame = 0
local ev = 1

ROMREADS_TAPS = {
  space:install_read_tap(0x0000, 0xBFFF, "romreads", function(offset, data, mask)
    local pc = curpc.value
    if (offset - pc) & 0xFFFF >= 4 then  -- not the instruction's own bytes
      seen[(page << 32) | (offset << 16) | pc] = true
    end
  end),
  space:install_write_tap(0xFB40, 0xFB40, "romreads_bank", function(offset, data, mask)
    page = (data ~ 4) & 7
  end),
}

local function field(port, name)
  local p = machine.ioport.ports[port]
  local f = p and p.fields[name]
  if not f then error("no input " .. port .. " / " .. name) end
  return f
end

ROMREADS_FRAME = emu.add_machine_frame_notifier(function()
  frame = frame + 1
  while CFG.events[ev] and CFG.events[ev].f <= frame do
    local e = CFG.events[ev]
    if e.v ~= 0 then field(e.port, e.field):set_value(1) else field(e.port, e.field):clear_value() end
    ev = ev + 1
  end
  if frame >= CFG.frames then
    local f = assert(io.open(CFG.reads_out, "w"))
    for key in pairs(seen) do
      f:write(string.format("%d,%04X,%04X\n", key >> 32, (key >> 16) & 0xFFFF, key & 0xFFFF))
    end
    f:close()
    machine:exit()
  end
end)
