-- MAME autoboot script for tools/reloc.py. Do not run it directly: reloc.py puts a CFG
-- table in front of it. Every CFG.every frames it appends the screen's pixels to
-- CFG.out, and plays the input events in CFG.events, as tools/trace.lua does.

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

local function field(port, name)
  local p = machine.ioport.ports[port]
  local f = p and p.fields[name]
  if not f then error("no input " .. port .. " / " .. name) end
  return f
end

RELOC_FRAME = emu.add_machine_frame_notifier(function()
  frame = frame + 1
  if frame % CFG.every == 0 then
    out:write((machine.screens[":screen"]:pixels()))  -- it also returns the size
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
    machine:exit()
  end
end)
