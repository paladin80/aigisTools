return {
  [1] = {name = "Dummy"},
  [2] = {name = "ATK"},
  [3] = {name = "ATK/alt"},
  [4] = {name = "DEF"},
  [5] = {name = "DEF/alt"},
  [6] = {name = "Range"},
  [7] = {name = "Attack count"},
  [8] = {name = "Splash mod"},
  [9] = {name = "Dodge(*)", type = "dodge"},
  [10] = {name = "Forsee"},
  [11] = {name = "HP"},
  [12] = {name = "Block"},
  [13] = {name = "Melee target count"},
  [14] = {name = "Attack cooldown"},
  [15] = {name = "Dancer mod"},
  --
  [19] = {name = "Magic resist"},
  --
  [21] = {name = "Missile", type = "missile"},
  [22] = {name = "Ranged target count"},
  -- 23 Meteor Tactics (projectile delay)
  -- 24 Shadow Sword (one attack?), Anelia SAW
  --
  [30] = {name = "Assassination"},
  [31] = {name = "Heal HP%"},
  [32] = {name = "Generate unit points"},
  [33] = {name = "Physical damage reduction"},
  [34] = {name = "Magic damage reduction"},
  [35] = {name = "Attack restores HP%"},
  [36] = {name = "Immortal", type = "flag"},
  [37] = {name = "Reduce enemy ATK"},
  [38] = {name = "Magic damage", type = "flag"},
  [39] = {name = "True damage", type = "flag"},
  [40] = {name = "Auto-revive to HP%"},
  [41] = {name = "Paralyze on skill end", type = "flag"},
  [42] = {name = "Lose HP% on skill end"},
  -- 43 affects nearby: Protetction = 1
  [44] = {name = "Melee attack area (?)", type = "flag"},
  -- 45 jSlow Magic
  [46] = {name = "Heal status"},
  [47] = {name = "Animation change", type = "enum", enum = {"STAND", "ATTACK", "ALL"}},
  -- 48 attack mode switch related? animation?
  [49] = {name = "Skill swap", type = "skill"},
  [50] = {name = "Auto-use", type = "flag"},
  [51] = {name = "Regeneration", type = "over_time"},
  [52] = {name = "Valkyrie UP modifier"},
  [53] = {name = "Ground only area attack", type = "raw"},
  [54] = {name = "Nullify attack chance"},
  --
  [55] = {name = "Permanent mode change", type = "flag"},
  --
  [57] = {name = "Counter"},
  -- 58 Cross Slash, Rock Cleaver
  [59] = {name = "Reduce enemy MR"},
  [60] = {name = "Reduce enemy DEF"},
  [61] = {name = "Cannot be targeted"},
  -- 62 Curse Voice
  -- 63 Curse Voice
  [64] = {name = "Heal by ATK"},
  [65] = {name = "Unit points over time", type = "over_time"},
  [66] = {name = "Bonus damage vs flying"},
  [67] = {name = "Bonus damage vs ground"},
  -- 68 Rock Cleaver, Final Trump Card
  -- 69 Cross Slash, Final Trump Card (FX)
  -- 70 Rock Cleaver, Final Trump Card (FX)
  [71] = {name = "Attack heals nearby allies"},
  --
  -- 76 True Silver's Brilliance (disable mithril arms block?)
  -- 77 True Silver's Brilliance (boost mithril arms crit rate?)
  --
  [84] = {name = "Unit cost"},
  [85] = {name = "ATK with rarity"},
  [86] = {name = "Lose HP% on skill end with rarity"},
  [87] = {name = "DEF with rarity"},
  [89] = {name = "Type-C Attack mod"},
  [90] = {name = "Type-C Defense mod"},
  [91] = {name = "Cannot be healed"},
  [95] = {name = "% Current health damage"},
  --
  -- 107 used by Raise Morale (permanent?)
  [108] = {name = "Lose HP%"},
  --
  -- 110 used by Heal I/II/III = 0 (added in patch, effect unknown)
  [120] = {name = "Generate Token Charges"},
  [122] = {name = "Add ability config", type = "ability"},
  [133] = {name = "Withdraw with Redeploy (FPS Wait)"},
  [153] = {name = "Revive on skill", type = "ability"},
   -- 173/177 Used by Solais skills
  [173] = {name = "Scaling Attack - Frames per Tick/Tick Rate/Max/Inc or Dec", type = "over_time"},
  [177] = {name = "Scaling no. Targets - Frames per Tick/Tick Rate/Max/Inc or Dec", type = "over_time"},
  [193] = {name = "Detonate Token"},
   -- 193 Used by Ambrose skills
}