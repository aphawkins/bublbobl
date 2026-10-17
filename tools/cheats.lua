-- Cheats for tools/trace.py, which puts a CFG table in front of this file for the
-- recording and the traced replay alike, so a replay sees the same game as the recording.
--
-- CFG.round (1-100): start each game on that round instead of round 1. The game keeps
-- the round in ROUND_MAIN (E64B), from 0; the MCU's round counter is not used. At game
-- start 1DCD writes 0 there, and this tap turns that 0 into CFG.round - 1. The round
-- record, palette and enemies are all loaded from ROUND_MAIN after that, and clearing a
-- round adds 1 as usual (1E4A).
--
-- CFG.boss_hits (0-80): the round 100 boss starts with that many hits taken. The count is
-- (IX+0B) of BOSS_SLOT, F2A1. BOSS_INIT clears it with 0D50 and hits add 1; from 0x46 the
-- boss flashes (bank0:AE73), and from 0x50 (80) bank0:A960 defeats it the next time its X
-- is 80-87. This tap turns BOSS_INIT's clear into CFG.boss_hits, on round 100 only.

local cpu = manager.machine.devices[":maincpu"]
local curpc = cpu.state["CURPC"]
local space = cpu.spaces["program"]

-- Keep the taps referenced: the garbage collector would remove them.
if CFG.round and CFG.round > 1 then
  CHEAT_ROUND_TAP = space:install_write_tap(0xE64B, 0xE64B, "cheat_round",
    function(offset, data, mask)
      if curpc.value == 0x1DCD then return CFG.round - 1 end
    end)
end

if CFG.boss_hits and CFG.boss_hits > 0 then
  CHEAT_BOSS_TAP = space:install_write_tap(0xF2A1, 0xF2A1, "cheat_boss_hits",
    function(offset, data, mask)
      if curpc.value == 0x0D50 and space:read_u8(0xE64B) == 0x63 then return CFG.boss_hits end
    end)
end
