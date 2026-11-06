-- MAME autoboot script for tools/frameorder.py. Do not run it directly: frameorder.py puts a
-- CFG table and tools/cheats.lua in front of it. No debugger is needed.
--
-- Logs, in CFG.out, one line per event for the frames CFG.start to CFG.stop:
--   t,cpu,kind,addr,data,pc
-- t is in microseconds and is the running CPU's own local time. MAME runs the CPUs in turn in
-- slices of 1/6000 s, so the file is in slice order, not time order: frameorder.py sorts it.
-- kind: R and W are a read and a write of shared RAM. X is a mark: the CPU fetched the routine
-- at addr. I is the MCU's P1 b6 falling, which raises the main CPU's IRQ.
--
-- The MCU reaches shared RAM through its ports, so there are no addresses to tap. The bus is
-- rebuilt as MAME's bublbobl_mcu_port2_w does it: P2 b4 rising clocks the address in P4 and
-- P2 b0-3, with P1 b7 saying read or write.

local machine = manager.machine
local main = machine.devices[":maincpu"]
local sub = machine.devices[":subcpu"]
local mcu = machine.devices[":mcu"]
local main_space = main.spaces["program"]
local sub_space = sub.spaces["program"]
local mcu_space = mcu.spaces["program"]
local main_pc = main.state["CURPC"]
local sub_pc = sub.state["CURPC"]
local mcu_pc = mcu.state["CURPC"]

local on = false
local muted = false
local frame = 0
local page = 0
local out = assert(io.open(CFG.out, "w"))
out:write("t,cpu,kind,addr,data,pc\n")
local buffer, n = {}, 0

local function log(cpu, kind, addr, data, pc)
  n = n + 1
  buffer[n] = string.format("%.3f,%s,%s,%04X,%02X,%s", emu.time() * 1e6, cpu, kind, addr, data, pc)
end

local function flush()
  if n > 0 then out:write(table.concat(buffer, "\n", 1, n), "\n") end
  buffer, n = {}, 0
end

local function main_where()
  local pc = main_pc.value
  if pc >= 0x8000 and pc < 0xC000 then return string.format("bank%d:%04X", page, pc) end
  return string.format("%04X", pc)
end

-- Keep the taps referenced: the garbage collector would remove them.
FO_TAPS = {}
local function keep(tap) FO_TAPS[#FO_TAPS + 1] = tap end

local function tap_main(lo, hi)
  keep(main_space:install_read_tap(lo, hi, "fo_main_r", function(offset, data, mask)
    if on and not muted then log("main", "R", offset, data, main_where()) end
  end))
  keep(main_space:install_write_tap(lo, hi, "fo_main_w", function(offset, data, mask)
    if on then log("main", "W", offset, data, main_where()) end
  end))
end
tap_main(0xE000, 0xF7FF)
tap_main(0xFC00, 0xFFFF)

keep(main_space:install_write_tap(0xFB40, 0xFB40, "fo_bank",
  function(offset, data, mask) page = (data ~ 4) & 7 end))

keep(sub_space:install_read_tap(0xE000, 0xF7FF, "fo_sub_r", function(offset, data, mask)
  if on then log("sub", "R", offset, data, string.format("%04X", sub_pc.value)) end
end))
keep(sub_space:install_write_tap(0xE000, 0xF7FF, "fo_sub_w", function(offset, data, mask)
  if on then log("sub", "W", offset, data, string.format("%04X", sub_pc.value)) end
end))

local p1, p2, p3, p4 = 0xFF, 0, 0, 0
keep(mcu_space:install_write_tap(0x0002, 0x0007, "fo_mcu_ports", function(offset, data, mask)
  if offset == 2 then
    if on and p1 & 0x40 ~= 0 and data & 0x40 == 0 then
      log("mcu", "I", 0, data, string.format("%04X", mcu_pc.value))
    end
    p1 = data
  elseif offset == 3 then
    if on and p2 & 0x10 == 0 and data & 0x10 ~= 0 then
      local address = p4 | ((data & 0x0F) << 8)
      if address & 0x0C00 == 0x0C00 then
        local kind = p1 & 0x80 ~= 0 and "R" or "W"
        muted = true
        local value = kind == "W" and p3 or main_space:read_u8(0xF000 | address)
        muted = false
        log("mcu", kind, 0xF000 | address, value, string.format("%04X", mcu_pc.value))
      end
    end
    p2 = data
  elseif offset == 6 then
    p3 = data
  elseif offset == 7 then
    p4 = data
  end
end))

-- A mark fires on the fetch of its first byte. Loops refetch, so a mark that repeats with no
-- other mark from that CPU between is logged once.
local last = {}
local function marks(cpu, space, pc_state, list)
  for _, a in ipairs(list) do
    keep(space:install_read_tap(a, a, "fo_mark", function(offset, data, mask)
      if on and last[cpu] ~= offset and pc_state.value == offset then
        last[cpu] = offset
        log(cpu, "X", offset, 0, string.format("%04X", offset))
      end
    end))
  end
end
marks("main", main_space, main_pc, CFG.marks.main)
marks("sub", sub_space, sub_pc, CFG.marks.sub)
marks("mcu", mcu_space, mcu_pc, CFG.marks.mcu)

local function field(port, name)
  local p = machine.ioport.ports[port]
  local f = p and p.fields[name]
  if not f then error("no input " .. port .. " / " .. name) end
  return f
end

local ev = 1
FO_FRAME = emu.add_machine_frame_notifier(function()
  frame = frame + 1
  while CFG.events[ev] and CFG.events[ev].f <= frame do
    local e = CFG.events[ev]
    if e.v ~= 0 then field(e.port, e.field):set_value(1) else field(e.port, e.field):clear_value() end
    ev = ev + 1
  end
  on = frame >= CFG.start
  flush()
  if frame >= CFG.stop then
    out:close()
    machine:exit()
  end
end)
