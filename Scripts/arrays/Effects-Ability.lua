return {
  [1] = {name = "ATK on-hit mod", args = {"mod", "chance"}},
  [2] = {name = "ATK dragon mod", args = {"mod", "chance"}},
  [3] = {name = "ATK yokai mod", args = {"mod", "chance"}},
  [4] = {name = "ATK undead mod", args = {"mod", "chance"}},
  [5] = {name = "ATK demon mod", args = {"mod", "chance"}},
  [6] = {name = "ATK armored mod", args = {"mod", "chance"}},
  --
  [8] = {name = "Critical hit", args = {"chance", "mod", k_skill_chance_boost}},
  [9] = {name = "Critical heal", args = {"chance", "mod", k_skill_chance_boost}},
  [10] = {name = "Cost reduction", args = {"n", "filter"}},
  [11] = {name = "Enemy HP and ATK mod", args = {"percent"}},
  [12] = {name = "HP mod", args = {"percent", "filter"}},
  [13] = {name = "ATK mod", args = {"percent", "filter"}},
  [14] = {name = "DEF mod", args = {"percent", "filter"}},
  [15] = {name = "MR mod", args = {"add_n", "filter"}},
  [16] = {name = "Skill duration mod", args = {"percent", "filter"}},
  [17] = {name = "Heal HP", args = {"opt.percent", "opt.n"}},
  [18] = {name = "Eliminate cooldown", args = {"chance"}},
  [19] = {name = "Nullify attack", args = {"chance"}},
  [20] = {name = "Physical Evasion", args = {"add_percent"}},
  [21] = {name = "Range", args = {"add_n"}},
  [22] = {name = "True damage", args = {"chance"}},
  [23] = {name = "Assassinate", args = {"percent"}},
  [24] = {name = "Gold GET!", args = {"chance"}},
  [25] = {name = "Priority change", args = {"enum.priority"}},
  [26] = {name = "Projectile count", args = {"chance", "n", "delay"}},
  [27] = {name = "Weather cost reduction", args = {"enum.weather", "n"}},
  [28] = {name = "Weather ATK mod",args = {"enum.weather", "percent"}},
  [29] = {name = "Weather resist", args = {"enum.weather", "percent"}},
  [30] = {name = "Regenerate HP", args = {"opt.n", "delay", "opt.percent"}},
  [31] = {name = "Regeneration restriction", args = {"enum.state"}},
  [32] = {name = "Regeneration mod", args = {"enum.state", "_", "percent"}},
  [33] = {name = "Starting UP", args = {"add_n"}},
  [34] = {name = "Prevent status ailment"},
  [35] = {name = "Assassinate mod", args = {"percent"}},
  [36] = {name = "Attack restores HP%", args = {"percent"}},
  [37] = {name = "Received damage restores ally HP", args = {"percent"}},
  [38] = {name = "Instantly kill enemies below HP%", args = {"percent"}},
  [39] = {name = "Nullify attack restriction", args = {"enum.state"}},
  [40] = {name = "Reduce terrain effects", args = {"percent"}},
  -- 41 used for Nutaku feng-shui, but not really clear
  --
  [43] = {name = "Skill attack change", args = {"_", "range", "missile"}},
  [44] = {name = "Mutex (ATK/DEF/Cost)", args = {"mutex"}},
  [45] = {name = "Skill cooldown timer reduction", args = {"percent"}},
  [46] = {name = "ATK flying mod", args = {"mod", "chance"}},
  [47] = {name = "Recover UP upon withdrawl", args = {"percent"}},
  [48] = {name = "Assassinate (add)", args = {"add_percent"}},
  [49] = {name = "Low HP DEF bonus", args = {k_threshold_percent, "add_percent"}},
  [50] = {name = "Nearby status ailment recovery rate", args = {"percent"}},
  [51] = {name = "Tokenize", args = {"_", "filter"}},
  [52] = {name = "Mutex (HP)", args = {"mutex"}},
  [53] = {name = "Mutex (skill duration)", args = {"mutex"}},
  --
  [55] = {name = "Token count mod", args = {"n"}},
  [56] = {name = "Area attack", args = {"chance", "_", "range"}}, -- 60?
  [57] = {name = "Drop boost (affection gift)", args = {"add_percent"}},
  [58] = {name = "Drop boost (trust gift)", args = {"add_percent"}},
  [59] = {name = "Drop boost (demon crystal)", args = {"add_percent"}},
  [60] = {name = "Drop boost (armor)", args = {"add_percent"}},
  [61] = {name = "Drop boost (spirit)", args = {"add_percent"}},
  [62] = {name = "Skill initial timer mod", args = {"percent", "filter"}},
  --
  [64] = {name = "(Deprecated?) Enemy type filter", args = {"enum.enemy_type"}}, -- I believe the skill now handles this (Enchanter, Sukuha)
  [65] = {name = "Can't be healed"},
  [66] = {name = "Reincarnate", args = {"_", "delay"}}, -- 100?
  [67] = {name = "Reincarnate (regeneration)", args = {"n", "delay"}},
  --
  [69] = {name = "Cost increase", args = {"n"}}, -- 1?
  [70] = {name = "ATK mod (new)", args = {"percent", "_", "_", "mutex"}},
  [71] = {name = "DEF mod (new)", args = {"percent", "_", "_", "mutex"}},
  [72] = {name = "Command"},
  -- 73 AW Prince = 100, WE
  -- 74 AW Prince = 100, WE
  -- 75 AW Prince = 100, WE
  [76] = {name = "MR mod (new)", args = {"add_n", "_", "_", "mutex"}},
  [77] = {name = "Global regeneration", args = {"opt.n", "delay"}},
  --
  [78] = {name = "Gold boost", args = {"add_percent"}},
  [79] = {name = "Drop boost (silver)", args = {"add_percent"}},
  [80] = {name = "Drop boost (non-unit)", args = {"add_percent"}},
  [81] = {name = "Cost reduction (new)", args = {"n", "_", "_", "mutex"}},
  [82] = {name = "HP mod (new)", args = {"percent", "_", "_", "mutex"}},
  [83] = {name = "ATK mod (conditional)", args = {"percent"}},
  --
  [86] = {name = "Substitute own death for ally death"},
  [87] = {name = "HP mod (dynamic)", args = {"percent", "_", "_", "mutex.82"}},
  [88] = {name = "Gold GET! bonus", args = {"n"}},
  -- this is for skill riperino [89] = {name = "Type-C Attack mod", args = {"n"}},
  --
  [90] = {name = "Reduce enemy DEF on hit", args = {"percent", k_frames}},
  [91] = {name = "Reduce attack cooldown", args = {"percent", "_", "_", "mutex"}},
  [92] = {name = "Ranged target count", args = {"percent", "n"}}, -- ?
  --
  [97] = {name = "First unit doesn't count against deployment limit"},
  [98] = {name = "Degenerate HP", args = {"opt.n", "delay", "opt.percent"}},
  --
  [106] = {name = "Cost reduction (conditional)", args = {"_", "n"}},
  -- 107 Aoba
  [108] = {name = "Nekomata ATK penalty", args = k_nekomata},
  [109] = {name = "Nekomata DEF penalty", args = k_nekomata},
  --
  [110] = {name = "ATK mod per unit", args = {"percent", k_max_percent}},
  [111] = {name = "DEF mod per unit", args = {"percent", k_max_percent}},
  [112] = {name = "Makai adaptation (ATK)"},
  [113] = {name = "Makai adaptation (DEF)"},
  --
  [115] = {name = "Dancer attack bonus", args = {"percent", "_", "_", "mutex"}},
  [116] = {name = "Dancer defense bonus", args = {"percent", "_", "_", "mutex"}},
  --
  [119] = {name = "Reduce enemy HP", args = {"percent"}},
  [120] = {name = "Reduce enemy ATK", args = {"percent"}},
  [121] = {name = "Reduce enemy DEF", args = {"percent"}},
  [122] = {name = "Reduce enemy MR", args = {"percent"}},
  -- Halloween Memento
  [161] = {name = "%ATK buff per global enemy kill", args = {"percent"}},
}