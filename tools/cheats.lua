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
-- Where the code the taps below wait for is. tools/reloc.py moves it, and gives its addresses here.
local PC = CFG.pc or {round = 0x1DCD, boss = 0x0D50, pop = 0xA972,
                     pick = 0x85EB, pick_item = 0x863A, pick_end = 0x8667}

-- Keep the taps referenced: the garbage collector would remove them.
if CFG.round and CFG.round > 1 then
  CHEAT_ROUND_TAP = space:install_write_tap(0xE64B, 0xE64B, "cheat_round",
    function(offset, data, mask)
      if curpc.value == PC.round then return CFG.round - 1 end
    end)
end

if CFG.boss_hits and CFG.boss_hits > 0 then
  CHEAT_BOSS_TAP = space:install_write_tap(0xF2A1, 0xF2A1, "cheat_boss_hits",
    function(offset, data, mask)
      if curpc.value == PC.boss and space:read_u8(0xE64B) == 0x63 then return CFG.boss_hits end
    end)
end

-- CFG.boss_pop: when bank0:A972 traps the boss (BOSS_SLOT +0 = 2), this tap writes 6 instead.
-- Bit 2 is what a player touching the bubble sets, so the next BOSS_UPDATE pops it (sound 27).
if CFG.boss_pop then
  CHEAT_BOSS_POP_TAP = space:install_write_tap(0xF296, 0xF296, "cheat_boss_pop",
    function(offset, data, mask)
      if data == 0x02 and curpc.value == PC.pop then return 0x06 end
    end)
end

-- CFG.special (1-0x35): every round's special item is that SPECIAL_KIND, and it appears
-- F0 frames (4 s) into the round, the game's own short timer. SPECIAL_PICK (bank2:85EB) writes the kind to F45E; when no
-- SPECIAL_RULES counter is due it sets SPECIAL_STATE b3 (no item) at 863A instead, and this
-- turns that into the forced kind. While the item shows (SPECIAL_STATE b0) player 1's object
-- (word at P1_REC +3; OBJ_POS_LOAD reads the record's Y, X from it) is put on it, so
-- SPECIAL_TAKE runs. Kind 0E is the exception: it sets F513 = FF (as SPECIAL_PICK does at
-- 864C), and player 1 is put on F513's own item when it shows (F514 b0).
if CFG.special and CFG.special > 0 then
  local in_pick = function() local pc = curpc.value; return pc >= PC.pick and pc < PC.pick_end end
  CHEAT_SPECIAL_KIND = space:install_write_tap(0xF45E, 0xF45E, "cheat_special_kind",
    function(offset, data, mask) if in_pick() then return CFG.special end end)
  CHEAT_SPECIAL_STATE = space:install_write_tap(0xF45F, 0xF45F, "cheat_special_state",
    function(offset, data, mask)
      if curpc.value == PC.pick_item and data & 0x08 ~= 0 then
        if CFG.special == 0x0E then  -- kind 0E has no normal item: SPECIAL_PICK starts F513 instead
          space:write_u8(0xF513, 0xFF)
          return
        end
        space:write_u8(0xF45E, CFG.special)
        return data & 0xF7
      end
    end)
  CHEAT_SPECIAL_TIMER = space:install_write_tap(0xF461, 0xF462, "cheat_special_timer",
    function(offset, data, mask)
      if in_pick() then return offset == 0xF461 and 0xF0 or 0 end
    end)
  CHEAT_SPECIAL_FRAME = emu.add_machine_frame_notifier(function()
    local shown = space:read_u8(0xF45F) & 1 ~= 0 or (CFG.special == 0x0E and space:read_u8(0xF514) & 1 ~= 0)
    if shown and space:read_u8(0xE691) & 1 ~= 0 then
      local obj = space:read_u8(0xE694) | (space:read_u8(0xE695) << 8)
      space:write_u8(obj, space:read_u8(0xE2B1))
      space:write_u8(obj + 2, space:read_u8(0xE2B3))
    end
  end)
end

-- CFG.clear (with CFG.special): once the item is taken (SPECIAL_STATE b0 clear again after
-- it showed), ENEMY_TOTAL (ED3D) is written 0 each frame, as if every enemy were gone. The
-- enemies stay on screen; the code that waits for a cleared round (such as REC_F46B_RUN,
-- which kinds 1E-28 start) runs.
if CFG.special and CFG.special > 0 and CFG.clear then
  local shown = false
  CHEAT_CLEAR_FRAME = emu.add_machine_frame_notifier(function()
    local state = space:read_u8(0xF45F)
    if state & 1 ~= 0 then shown = true
    elseif shown and space:read_u8(0xED3D) ~= 0 then space:write_u8(0xED3D, 0) end
  end)
end

-- CFG.poke: {{addr, value}, ...} (trace.py --poke): each address holds its value from frame 240,
-- after the start-up RAM test (which hangs at 0216 if a byte will not change). From then it is
-- written at the end of every frame, and a write tap turns every write the game makes into it.
if CFG.poke and #CFG.poke > 0 then
  local frames = 0
  CHEAT_POKE_TAPS = {}
  CHEAT_POKE_FRAME = emu.add_machine_frame_notifier(function()
    frames = frames + 1
    if frames < 240 then return end
    if #CHEAT_POKE_TAPS == 0 then
      for i, p in ipairs(CFG.poke) do
        CHEAT_POKE_TAPS[i] = space:install_write_tap(p[1], p[1], "cheat_poke_" .. i,
          function(offset, data, mask) return p[2] end)
      end
    end
    for _, p in ipairs(CFG.poke) do space:write_u8(p[1], p[2]) end
  end)
end
