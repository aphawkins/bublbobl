-- Start a game on round CFG.round (1-100) instead of round 1. tools/trace.py puts a CFG
-- table in front of this file, for the recording and the traced replay alike, so a
-- replay sees the same rounds as the recording.
--
-- The game keeps the round in ROUND_MAIN (E64B), from 0. The MCU's round counter is not
-- used. At game start 1DCD writes 0 there; this tap turns that 0 into CFG.round - 1. The
-- round record, palette and enemies are all loaded from ROUND_MAIN after that, and
-- clearing a round adds 1 as usual (1E4A).

if CFG.round and CFG.round > 1 then
  local cpu = manager.machine.devices[":maincpu"]
  local curpc = cpu.state["CURPC"]
  -- Keep the tap referenced: the garbage collector would remove it.
  START_ROUND_TAP = cpu.spaces["program"]:install_write_tap(0xE64B, 0xE64B, "start_round",
    function(offset, data, mask)
      if curpc.value == 0x1DCD then return CFG.round - 1 end
    end)
end
