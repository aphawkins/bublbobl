-- Logs the sound chips' register writes after each injected sound command.
-- Run by tools/soundcmp.py, which puts a CFG table (cmds, out) in front.
local m = manager.machine
local main = m.devices[":maincpu"].spaces["program"]
local aud = m.devices[":audiocpu"].spaces["program"]
local log = {}
local t0 = 0
local cur = ""
H = {}
local function tap(base, name)
  H[#H+1] = aud:install_write_tap(base, base + 1, name, function(off, data)
    log[#log+1] = string.format("%s,%.5f,%s,%d,%02X", cur, m.time:as_double() - t0, name, off, data)
    return data
  end)
end
tap(0x9000, "opn"); tap(0xA000, "opl")
local frame, idx = 0, 0
local next_at = CFG.start
emu.register_frame_done(function()
  frame = frame + 1
  main:write_u8(0xFA80, 0) -- the watchdog
  if frame == CFG.start - 30 then local st = m.devices[':maincpu'].state; st['IFF1'].value = 0; st['IFF2'].value = 0; st['PC'].value = 0x01ED end
  if frame == next_at and idx < #CFG.cmds then
    idx = idx + 1
    cur = string.format("%02X", CFG.cmds[idx])
    t0 = m.time:as_double()
    main:write_u8(0xFA00, 0xEE) -- sound off clears the records
    main:write_u8(0xFA00, 0xEF)
    main:write_u8(0xFA00, CFG.cmds[idx])
    next_at = frame + CFG.gap
  elseif frame == next_at then
    local f = io.open(CFG.out, "w"); for _, l in ipairs(log) do f:write(l, "\n") end; f:close()
    m:exit()
  end
end)
