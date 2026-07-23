extends Node
func _upgrades(): pass

const COMMON = 0
const RARE = 1
const EPIC = 2

const LIST = [
	{"id": "hollow", "name": "HOLLOW POINTS", "desc": "Rifle damage +30%", "tier": COMMON, "cap": 5, "mul": {"damage": 1.3}},
	{"id": "rifling", "needs": {"hollow": 1}, "name": "MATCH RIFLING", "desc": "Rifle damage +55%", "tier": RARE, "cap": 3, "mul": {"damage": 1.55}},
	{"id": "buckshot", "name": "FAT BUCKSHOT", "desc": "Shotgun damage +30%", "tier": COMMON, "cap": 5, "mul": {"shotGunDmg": 1.3}},
	{"id": "choke", "name": "TIGHT CHOKE", "desc": "Shotgun range falloff starts 60% further", "tier": COMMON, "cap": 3, "mul": {"shotGunFalloffRange": 1.6, "shotGunCloseRange": 1.4}},
	{"id": "slugs", "needs": {"choke": 1}, "name": "SOLID SLUGS", "desc": "Shotgun keeps 80% damage at any range", "tier": RARE, "cap": 1, "set": {"shotGunMinDmgMult": 0.8}},
	{"id": "magnum", "needs": {"buckshot": 1}, "name": "MAGNUM LOAD", "desc": "Shotgun damage +60%, fires slower", "tier": RARE, "cap": 3, "mul": {"shotGunDmg": 1.6}, "special": "slowshotgun"},
	{"id": "apround", "name": "AP ROUNDS", "desc": "Sniper damage +40%", "tier": COMMON, "cap": 5, "mul": {"sniperDmg": 1.4}},
	{"id": "boltwork", "name": "SLICK BOLT", "desc": "Sniper cooldown -25%", "tier": COMMON, "cap": 4, "mul": {"sniperCooldown": 0.75}},
	{"id": "railgun", "needs": {"apround": 1}, "name": "RAILGUN CORE", "desc": "Sniper damage +120%, cooldown +30%", "tier": EPIC, "cap": 2, "mul": {"sniperDmg": 2.2, "sniperCooldown": 1.3}},
	{"id": "steady", "name": "STEADY HANDS", "desc": "Hipfire spread -35%", "tier": COMMON, "cap": 3, "mul": {"hipfireSpread": 0.65}},
	{"id": "trigger", "name": "LOOSE TRIGGER", "desc": "Fire rate +20%", "tier": RARE, "cap": 4, "special": "firerate"},
	{"id": "overclock", "name": "OVERCLOCKED", "desc": "Fire rate +45%, damage -10%", "tier": EPIC, "cap": 2, "mul": {"damage": 0.9}, "special": "firerate2"},
	{"id": "crit1", "name": "WEAK POINTS", "desc": "+12% critical chance", "tier": COMMON, "cap": 6, "add": {"critChance": 0.12}},
	{"id": "crit2", "needs": {"crit1": 1}, "name": "EXECUTIONER", "desc": "Criticals deal +75% more", "tier": RARE, "cap": 4, "add": {"critMult": 0.75}},
	{"id": "deadeye", "name": "DEADEYE", "desc": "+25% critical chance", "tier": EPIC, "cap": 3, "add": {"critChance": 0.25}},

	{"id": "vitality", "name": "VITALITY", "desc": "Max health +25", "tier": COMMON, "cap": 6, "special": "maxhp25"},
	{"id": "bulwark", "needs": {"vitality": 1}, "name": "BULWARK", "desc": "Max health +60, heal to full", "tier": RARE, "cap": 3, "special": "maxhp60"},
	{"id": "bandage", "name": "FIELD DRESSING", "desc": "Heal 40 health now", "tier": COMMON, "cap": 99, "special": "heal40"},
	{"id": "medkit", "name": "FULL MEDKIT", "desc": "Heal to full", "tier": RARE, "cap": 99, "special": "healfull"},
	{"id": "vampire", "name": "VAMPIRIC ROUNDS", "desc": "Heal 4% of damage dealt", "tier": RARE, "cap": 5, "add": {"lifesteal": 0.04}},
	{"id": "harvest", "name": "HARVEST", "desc": "Kills heal +6 health", "tier": COMMON, "cap": 5, "add": {"killHeal": 6.0}},
	{"id": "thorns", "name": "RETALIATION", "desc": "Taking a hit deals 25 damage nearby", "tier": RARE, "cap": 4, "add": {"thorns": 25.0}},
	{"id": "adrenaline", "needs": {"harvest": 1}, "name": "ADRENALINE", "desc": "Kills heal +12 and restore stamina", "tier": EPIC, "cap": 3, "add": {"killHeal": 12.0}, "special": "killstam"},

	{"id": "sprint", "name": "LIGHT BOOTS", "desc": "Move speed +12%", "tier": COMMON, "cap": 5, "mul": {"upSpeed": 1.12}},
	{"id": "bloodrush", "needs": {"sprint": 1}, "name": "BLOOD RUSH", "desc": "Move speed +25%", "tier": RARE, "cap": 3, "mul": {"upSpeed": 1.25}},
	{"id": "springs", "name": "COILED LEGS", "desc": "Jump height +15%", "tier": COMMON, "cap": 4, "mul": {"upJump": 1.15}},
	{"id": "doublejump", "name": "SECOND WIND", "desc": "Gain an extra mid-air jump", "tier": EPIC, "cap": 3, "add": {"extraJumps": 1}},
	{"id": "dashpow", "name": "KICK THRUSTERS", "desc": "Dash distance +25%", "tier": COMMON, "cap": 4, "mul": {"dashBoost": 1.25}},
	{"id": "dashcd", "name": "QUICK RECOVERY", "desc": "Dash cooldown -30%", "tier": COMMON, "cap": 4, "mul": {"dashCooldown": 0.7}},
	{"id": "blink", "needs": {"dashpow": 1, "dashcd": 1}, "name": "BLINK DRIVE", "desc": "Dash distance +45%, cooldown -25%", "tier": EPIC, "cap": 2, "mul": {"dashBoost": 1.45, "dashCooldown": 0.75}},
	{"id": "airctrl", "name": "AIR BRAKES", "desc": "Air control +45%", "tier": COMMON, "cap": 4, "mul": {"airAccel": 1.45}},
	{"id": "slick", "name": "SLICK SOLES", "desc": "Slides carry further", "tier": COMMON, "cap": 4, "mul": {"slideFactor": 1.25, "slideDrain": 0.75}},
	{"id": "wallcheap", "name": "GECKO GRIP", "desc": "Wall jumps cost 40% less stamina", "tier": COMMON, "cap": 3, "mul": {"wallJumpCost": 0.6}},

	{"id": "lungs", "name": "BIG LUNGS", "desc": "Stamina regen +35%", "tier": COMMON, "cap": 5, "mul": {"staminaRegen": 1.35}},
	{"id": "quickbreath", "name": "QUICK BREATH", "desc": "Stamina starts regenerating 50% sooner", "tier": COMMON, "cap": 3, "mul": {"staminaDelay": 0.5}},
	{"id": "efficient", "name": "EFFICIENT FORM", "desc": "All stamina costs -20%", "tier": RARE, "cap": 4, "mul": {"upStamCost": 0.8}},
	{"id": "marathon", "needs": {"lungs": 1, "efficient": 1}, "name": "MARATHON", "desc": "Stamina regen +60%, costs -15%", "tier": EPIC, "cap": 2, "mul": {"staminaRegen": 1.6, "upStamCost": 0.85}},

	{"id": "slamdmg", "name": "PILEDRIVER", "desc": "Slam damage +50%", "tier": COMMON, "cap": 5, "mul": {"slamDmgPerUnit": 1.5, "slamMaxDmg": 1.5}},
	{"id": "slamcheap", "name": "HEAVY BOOTS", "desc": "Slam costs 50% less stamina", "tier": COMMON, "cap": 3, "mul": {"slamCost": 0.5}},
	{"id": "meteor", "needs": {"slamdmg": 1}, "name": "METEOR", "desc": "Slam damage +90% and falls faster", "tier": RARE, "cap": 3, "mul": {"slamDmgPerUnit": 1.9, "slamMaxDmg": 1.9, "slamAccel": 1.4}},
	{"id": "shockwave", "needs": {"meteor": 1}, "name": "SHOCKWAVE", "desc": "Slam max damage +150", "tier": EPIC, "cap": 3, "add": {"slamMaxDmg": 150.0}},

	{"id": "glasscannon", "name": "GLASS CANNON", "desc": "All weapon damage +70%, max health -30", "tier": EPIC, "cap": 2, "mul": {"damage": 1.7, "shotGunDmg": 1.7, "sniperDmg": 1.7}, "special": "hpdown30"},
	{"id": "berserk", "name": "BERSERKER", "desc": "All weapon damage +35%", "tier": RARE, "cap": 4, "mul": {"damage": 1.35, "shotGunDmg": 1.35, "sniperDmg": 1.35}},
	{"id": "juggernaut", "needs": {"vitality": 2}, "name": "JUGGERNAUT", "desc": "Max health +100, move speed -8%", "tier": RARE, "cap": 3, "mul": {"upSpeed": 0.92}, "special": "maxhp100"},
	{"id": "featherweight", "name": "FEATHERWEIGHT", "desc": "Speed +18% and jump +10%, max health -15", "tier": RARE, "cap": 3, "mul": {"upSpeed": 1.18, "upJump": 1.1}, "special": "hpdown15"},
	{"id": "cure", "name": "ANTIVENOM", "desc": "Clear all paralysis and resist it", "tier": RARE, "cap": 4, "mul": {"paraChipDmg": 0.6}, "special": "curepara"},
	{"id": "steadycam", "name": "GYRO STOCK", "desc": "Much less recoil and camera roll", "tier": COMMON, "cap": 3, "mul": {"maxRoll": 0.6}, "special": "recoil"},
	{"id": "greed", "name": "GREED", "desc": "Score from rooms +25%", "tier": COMMON, "cap": 6, "special": "score25"},
	{"id": "jackpot", "needs": {"greed": 1}, "name": "JACKPOT", "desc": "Score from rooms +60%", "tier": RARE, "cap": 4, "special": "score60"},
	{"id": "scholar", "name": "SCHOLAR", "desc": "See one extra upgrade choice", "tier": EPIC, "cap": 2, "special": "extrachoice"},

	{"id": "frag", "name": "FRAG ROUNDS", "desc": "Kills explode for 25 damage nearby", "tier": COMMON, "cap": 5, "add": {"explosive": 25.0}},
	{"id": "cluster", "needs": {"frag": 1}, "name": "CLUSTER LOAD", "desc": "Kills explode for 55 damage nearby", "tier": RARE, "cap": 4, "add": {"explosive": 55.0}},
	{"id": "demo", "needs": {"cluster": 1}, "name": "DEMOLITIONIST", "desc": "Kill explosions deal +90 and reach 60% further", "tier": EPIC, "cap": 2, "add": {"explosive": 90.0}, "mul": {"explosiveRange": 1.6}},
	{"id": "shrapnel", "needs": {"frag": 1}, "name": "WIDE SHRAPNEL", "desc": "Kill explosions reach 45% further", "tier": COMMON, "cap": 3, "mul": {"explosiveRange": 1.45}},

	{"id": "momentum", "name": "MOMENTUM", "desc": "Up to +25% damage the faster you move", "tier": RARE, "cap": 4, "add": {"momentum": 0.25}},
	{"id": "hitrun", "needs": {"momentum": 1}, "name": "HIT AND RUN", "desc": "Up to +50% damage while moving, speed +10%", "tier": EPIC, "cap": 2, "add": {"momentum": 0.5}, "mul": {"upSpeed": 1.1}},

	{"id": "kevlar", "name": "KEVLAR WEAVE", "desc": "Take 10% less damage", "tier": COMMON, "cap": 5, "mul": {"upArmor": 0.9}},
	{"id": "plates", "needs": {"kevlar": 1}, "name": "PLATE CARRIER", "desc": "Take 22% less damage", "tier": RARE, "cap": 3, "mul": {"upArmor": 0.78}},
	{"id": "turtle", "needs": {"plates": 1}, "name": "TURTLE SHELL", "desc": "Take 40% less damage, move speed -8%", "tier": EPIC, "cap": 2, "mul": {"upArmor": 0.6, "upSpeed": 0.92}},

	{"id": "regen", "name": "REGENERATION", "desc": "Recover 1.5 health per second", "tier": COMMON, "cap": 5, "add": {"regen": 1.5}},
	{"id": "trollblood", "needs": {"regen": 1}, "name": "TROLL BLOOD", "desc": "Recover 4 health per second", "tier": RARE, "cap": 3, "add": {"regen": 4.0}},
	{"id": "revive", "name": "SECOND LIFE", "desc": "Survive one fatal hit at full health", "tier": EPIC, "cap": 3, "add": {"reviveCharges": 1}},

	{"id": "heavybarrel", "needs": {"rifling": 1}, "name": "HEAVY BARREL", "desc": "Rifle damage +45%, spread -30%", "tier": RARE, "cap": 3, "mul": {"damage": 1.45, "hipfireSpread": 0.7}},
	{"id": "sawnoff", "needs": {"buckshot": 1}, "name": "SAWED OFF", "desc": "Shotgun damage +50% but falls off much sooner", "tier": RARE, "cap": 3, "mul": {"shotGunDmg": 1.5, "shotGunCloseRange": 0.6, "shotGunFalloffRange": 0.7}},
	{"id": "scope", "name": "PRECISION SCOPE", "desc": "Sniper damage +25% and zooms deeper", "tier": COMMON, "cap": 2, "mul": {"sniperDmg": 1.25, "scopedFov": 0.75}},

	{"id": "terminal", "name": "TERMINAL VELOCITY", "desc": "Slams reach lethal speed much sooner", "tier": COMMON, "cap": 4, "mul": {"slamVeloc": 1.35, "slamMaxVeloc": 1.25}},
	{"id": "surfer", "name": "SURFER", "desc": "Slides grip harder and carry further", "tier": COMMON, "cap": 4, "mul": {"slideDownforce": 1.4, "slideFactor": 1.15}},
	{"id": "speeddemon", "name": "SPEED DEMON", "desc": "Move speed +15%, dash cooldown -15%", "tier": RARE, "cap": 4, "mul": {"upSpeed": 1.15, "dashCooldown": 0.85}},
	{"id": "hangtime", "name": "HANG TIME", "desc": "Jump +12% and air control +30%", "tier": COMMON, "cap": 4, "mul": {"upJump": 1.12, "airAccel": 1.3}},

	{"id": "thickskin", "name": "THICK SKIN", "desc": "Paralysis chips away 40% slower", "tier": COMMON, "cap": 4, "mul": {"paraChipRate": 1.6}},
	{"id": "numblegs", "name": "NUMB LEGS", "desc": "Dash stays strong while paralysed", "tier": COMMON, "cap": 3, "mul": {"paraDashMult": 1.5}},

	{"id": "bloodpact", "name": "BLOOD PACT", "desc": "All weapon damage +50%, take 20% more damage", "tier": EPIC, "cap": 2, "mul": {"damage": 1.5, "shotGunDmg": 1.5, "sniperDmg": 1.5, "upArmor": 1.2}},
	{"id": "leech", "name": "LEECH FIELD", "desc": "Lifesteal +3% and kills heal +4", "tier": COMMON, "cap": 5, "add": {"lifesteal": 0.03, "killHeal": 4.0}},
	{"id": "warcry", "needs": {"thorns": 1}, "name": "WAR CRY", "desc": "Retaliation +40 damage and kills restore stamina", "tier": RARE, "cap": 3, "add": {"thorns": 40.0}, "special": "killstam"},

	{"id": "ricochet", "name": "RICOCHET", "desc": "Shots bounce off walls once more", "tier": COMMON, "cap": 3, "add": {"ricochet": 1}},
	{"id": "rubber", "needs": {"ricochet": 1}, "name": "RUBBER ROUNDS", "desc": "Shots bounce off walls 2 more times", "tier": RARE, "cap": 3, "add": {"ricochet": 2}},
	{"id": "pinball", "needs": {"rubber": 1}, "name": "PINBALL", "desc": "3 more wall bounces and +20% weapon damage", "tier": EPIC, "cap": 2, "add": {"ricochet": 3}, "mul": {"damage": 1.2, "shotGunDmg": 1.2, "sniperDmg": 1.2}},
	{"id": "banked", "needs": {"ricochet": 1}, "name": "BANK SHOT", "desc": "1 more bounce, +15% critical chance", "tier": COMMON, "cap": 3, "add": {"ricochet": 1, "critChance": 0.15}},

	{"id": "overpen", "name": "OVERPENETRATION", "desc": "Shots pass through 1 more enemy", "tier": COMMON, "cap": 3, "add": {"pierce": 1}},
	{"id": "railspike", "needs": {"overpen": 1}, "name": "RAIL SPIKE", "desc": "Shots pass through 2 more enemies", "tier": RARE, "cap": 3, "add": {"pierce": 2}},
	{"id": "skewer", "needs": {"railspike": 1}, "name": "SKEWER", "desc": "Shots pass through 4 more enemies, +25% damage", "tier": EPIC, "cap": 2, "add": {"pierce": 4}, "mul": {"damage": 1.25, "shotGunDmg": 1.25, "sniperDmg": 1.25}},
	{"id": "leasebreak", "needs": {"rubber": 1, "railspike": 1}, "name": "LEASE BREAKER", "desc": "2 more bounces and 1 more pass-through", "tier": EPIC, "cap": 2, "add": {"ricochet": 2, "pierce": 1}},

	{"id": "splinter", "name": "SPLINTER", "desc": "Impacts throw 2 fragments", "tier": COMMON, "cap": 4, "add": {"splitShards": 2}},
	{"id": "fragload", "needs": {"splinter": 1}, "name": "FRAGMENTATION", "desc": "Impacts throw 3 fragments, fragments hit harder", "tier": RARE, "cap": 3, "add": {"splitShards": 3, "splitMult": 0.15}},
	{"id": "shatter", "needs": {"fragload": 1}, "name": "SHATTER", "desc": "Impacts throw 5 fragments", "tier": EPIC, "cap": 2, "add": {"splitShards": 5}},
	{"id": "sharpfrag", "needs": {"splinter": 1}, "name": "SHARP FRAGMENTS", "desc": "Fragments deal +30% and fly 50% further", "tier": COMMON, "cap": 3, "add": {"splitMult": 0.3}, "mul": {"splitRange": 1.5}},

	{"id": "smartround", "name": "SMART ROUNDS", "desc": "Shots curve toward nearby enemies", "tier": RARE, "cap": 3, "add": {"homing": 0.35}},
	{"id": "guidance", "needs": {"smartround": 1}, "name": "GUIDANCE CHIP", "desc": "Shots curve hard toward enemies, wider search", "tier": EPIC, "cap": 2, "add": {"homing": 0.6}, "special": "widehoming"},

	{"id": "toxic", "name": "TOXIC ROUNDS", "desc": "Hits poison for 6 damage per second", "tier": COMMON, "cap": 5, "add": {"poison": 6.0}},
	{"id": "mould", "needs": {"toxic": 1}, "name": "BLACK MOULD", "desc": "Hits poison for 14 damage per second", "tier": RARE, "cap": 4, "add": {"poison": 14.0}},
	{"id": "decay", "needs": {"mould": 1}, "name": "DECAY", "desc": "Hits poison for 25 per second and it lasts 2s longer", "tier": EPIC, "cap": 2, "add": {"poison": 25.0}, "special": "poisonlong"},
	{"id": "damp", "needs": {"toxic": 1}, "name": "RISING DAMP", "desc": "Poison lasts 3 seconds longer", "tier": COMMON, "cap": 3, "special": "poisonlong3"},

	{"id": "coupdegrace", "name": "COUP DE GRACE", "desc": "Finish off enemies left under 12 health", "tier": COMMON, "cap": 4, "add": {"executeHp": 12.0}},
	{"id": "foreclose", "needs": {"coupdegrace": 1}, "name": "FORECLOSURE", "desc": "Finish off enemies left under 30 health", "tier": RARE, "cap": 3, "add": {"executeHp": 30.0}},
	{"id": "finalnotice", "needs": {"foreclose": 1}, "name": "FINAL NOTICE", "desc": "Finish off enemies left under 70 health", "tier": EPIC, "cap": 2, "add": {"executeHp": 70.0}},

	{"id": "carryover", "name": "CARRY OVER", "desc": "Half of overkill damage jumps to another enemy", "tier": COMMON, "cap": 4, "add": {"overkill": 0.5}},
	{"id": "liquidate", "needs": {"carryover": 1}, "name": "LIQUIDATION", "desc": "All overkill damage jumps to another enemy", "tier": RARE, "cap": 3, "add": {"overkill": 1.0}},

	{"id": "laststand", "needs": {"cornered": 1}, "name": "LAST STAND", "desc": "Up to +50% damage the lower your health", "tier": RARE, "cap": 3, "add": {"lowHpDmg": 0.5}},
	{"id": "desperation", "needs": {"laststand": 1}, "name": "DESPERATION", "desc": "Up to +100% damage the lower your health", "tier": EPIC, "cap": 2, "add": {"lowHpDmg": 1.0}},
	{"id": "cornered", "name": "CORNERED", "desc": "Up to +35% damage when hurt, take 10% less", "tier": COMMON, "cap": 4, "add": {"lowHpDmg": 0.35}, "mul": {"upArmor": 0.9}},

	{"id": "killstreak", "name": "KILL STREAK", "desc": "+4% damage per recent kill, up to 10", "tier": COMMON, "cap": 5, "add": {"comboDmg": 0.04}},
	{"id": "snowball", "needs": {"killstreak": 1}, "name": "SNOWBALL", "desc": "+8% damage per recent kill, up to 10", "tier": RARE, "cap": 3, "add": {"comboDmg": 0.08}},
	{"id": "rampage", "needs": {"snowball": 1}, "name": "RAMPAGE", "desc": "+15% damage per recent kill, streak lasts longer", "tier": EPIC, "cap": 2, "add": {"comboDmg": 0.15}, "special": "combowindow"},
	{"id": "bloodscent", "needs": {"killstreak": 1}, "name": "SCENT OF BLOOD", "desc": "Streaks last 2s longer and kills heal +5", "tier": COMMON, "cap": 3, "add": {"killHeal": 5.0}, "special": "combowindow"},

	{"id": "morepellets", "name": "WIDER SPREAD", "desc": "Shotgun fires 2 extra pellets", "tier": RARE, "cap": 4, "special": "pellets2"},
	{"id": "doublebarrel", "needs": {"morepellets": 1}, "name": "DOUBLE BARREL", "desc": "Shotgun fires 4 extra pellets, +20% damage", "tier": EPIC, "cap": 2, "mul": {"shotGunDmg": 1.2}, "special": "pellets4"},
	{"id": "pumpaction", "name": "PUMP ACTION", "desc": "Shotgun fires 25% faster", "tier": COMMON, "cap": 3, "special": "pumpaction"},

	{"id": "heavyrounds", "name": "HEAVY ROUNDS", "desc": "All weapon damage +80%, fire rate -25%", "tier": EPIC, "cap": 2, "mul": {"damage": 1.8, "shotGunDmg": 1.8, "sniperDmg": 1.8}, "special": "fireratedown"},
	{"id": "hairtrigger", "name": "HAIR TRIGGER", "desc": "Fire rate +70%, much wider spread", "tier": RARE, "cap": 3, "mul": {"hipfireSpread": 1.6}, "special": "firerate70"},

	{"id": "insurance", "name": "HEALTH INSURANCE", "desc": "Survive one fatal hit and heal to full", "tier": RARE, "cap": 3, "add": {"reviveCharges": 1}, "special": "healfull"},
	{"id": "sickpay", "name": "SICK PAY", "desc": "Recover 2.5 health per second, kills heal +5", "tier": COMMON, "cap": 4, "add": {"regen": 2.5, "killHeal": 5.0}},
	{"id": "catreflex", "name": "CAT REFLEXES", "desc": "An extra mid-air jump and +30% air control", "tier": RARE, "cap": 3, "add": {"extraJumps": 1}, "mul": {"airAccel": 1.3}},
	{"id": "wallrat", "name": "WALL RAT", "desc": "Wall jumps cost 50% less and speed +10%", "tier": COMMON, "cap": 4, "mul": {"wallJumpCost": 0.5, "upSpeed": 1.1}},
	{"id": "secondlung", "name": "SECOND LUNG", "desc": "Stamina regen +45% and slides drain 30% less", "tier": COMMON, "cap": 4, "mul": {"staminaRegen": 1.45, "slideDrain": 0.7}},
	{"id": "sniperfrag", "name": "SPLIT ROUND", "desc": "Sniper +30% damage, impacts throw 2 fragments", "tier": RARE, "cap": 3, "mul": {"sniperDmg": 1.3}, "add": {"splitShards": 2}},
	{"id": "ecoround", "needs": {"toxic": 1, "frag": 1}, "name": "SALTED EARTH", "desc": "Poison +8/s and kill explosions +35", "tier": RARE, "cap": 3, "add": {"poison": 8.0, "explosive": 35.0}},
	{"id": "auditor", "name": "THE AUDITOR", "desc": "+18% crit chance, criticals deal +50% more", "tier": RARE, "cap": 4, "add": {"critChance": 0.18, "critMult": 0.5}},

	{"id": "phoenix", "name": "PHOENIX", "desc": "Survive a fatal hit, erupt for 120 nearby and burn for 2s", "tier": EPIC, "cap": 2, "add": {"reviveCharges": 1, "phoenixBlast": 120.0, "phoenixInvuln": 2.0}},
	{"id": "phoenix2", "name": "DOUBLE PHOENIX", "desc": "Two more lives, eruption +180 and 1.5s longer", "tier": EPIC, "cap": 2, "needs": {"phoenix": 1}, "add": {"reviveCharges": 2, "phoenixBlast": 180.0, "phoenixInvuln": 1.5}, "mul": {"phoenixRange": 1.4}},
]

static func byId(id : String):
	for u in LIST:
		if u["id"] == id:
			return u
	return null

static func _meets(u : Dictionary, taken : Dictionary) -> bool:
	if not u.has("needs"):
		return true
	for id in u["needs"]:
		if taken.get(id, 0) < u["needs"][id]:
			return false
	return true

static func roll(rng : RandomNumberGenerator, taken : Dictionary, count : int) -> Array:
	var pool = []
	for u in LIST:
		if taken.get(u["id"], 0) < u["cap"] and _meets(u, taken):
			pool.append(u)
	var out = []
	while out.size() < count and pool.size() > 0:
		var total = 0.0
		for u in pool:
			total += _weight(u["tier"])
		var pickAt = rng.randf() * total
		var acc = 0.0
		var chosen = pool[0]
		for u in pool:
			acc += _weight(u["tier"])
			if acc >= pickAt:
				chosen = u
				break
		out.append(chosen)
		pool.erase(chosen)
	return out

static func _weight(tier : int) -> float:
	match tier:
		RARE: return 0.4
		EPIC: return 0.15
	return 1.0

static func apply(p, u : Dictionary):
	if u.has("mul"):
		for k in u["mul"]:
			p.set(k, p.get(k) * u["mul"][k])
	if u.has("add"):
		for k in u["add"]:
			p.set(k, p.get(k) + u["add"][k])
	if u.has("set"):
		for k in u["set"]:
			p.set(k, u["set"][k])
	if u.has("special"):
		_special(p, u["special"])

static func _special(p, what : String):
	match what:
		"maxhp25":
			p.maxHealth += 25.0
			p.health = min(p.health + 25, p.maxHealth)
		"maxhp60":
			p.maxHealth += 60.0
			p.health = p.maxHealth
		"maxhp100":
			p.maxHealth += 100.0
			p.health = min(p.health + 100, p.maxHealth)
		"hpdown30":
			p.maxHealth = max(p.maxHealth - 30.0, 30.0)
			p.health = min(p.health, p.maxHealth)
		"hpdown15":
			p.maxHealth = max(p.maxHealth - 15.0, 30.0)
			p.health = min(p.health, p.maxHealth)
		"heal40":
			p.health = min(p.health + 40, p.maxHealth)
		"healfull":
			p.health = p.maxHealth
		"firerate":
			p.upFireRate *= 1.2
			p.animaPlayer.speed_scale = p.upFireRate
		"firerate2":
			p.upFireRate *= 1.45
			p.animaPlayer.speed_scale = p.upFireRate
		"slowshotgun":
			p.shotGunCdTimer.wait_time *= 1.35
		"killstam":
			p.killStam = true
		"curepara":
			p.paraLevel = 0
		"recoil":
			p.upKnock *= 0.6
		"score25":
			p.scoreMult += 0.25
		"score60":
			p.scoreMult += 0.6
		"extrachoice":
			p.extraChoice += 1
		"widehoming":
			p.homingCone += 8.0
			p.homingRange += 20.0
		"poisonlong":
			p.poisonTime += 2.0
		"poisonlong3":
			p.poisonTime += 3.0
		"combowindow":
			p.comboWindow += 2.0
		"pellets2":
			_addPellets(p, 2)
		"pellets4":
			_addPellets(p, 4)
		"pumpaction":
			p.shotGunCdTimer.wait_time *= 0.75
		"fireratedown":
			p.upFireRate *= 0.75
			p.animaPlayer.speed_scale = p.upFireRate
		"firerate70":
			p.upFireRate *= 1.7
			p.animaPlayer.speed_scale = p.upFireRate

static func _addPellets(p, n : int):
	if p.rayContainer == null or not p.rayContainer.has_method("addRay"):
		return
	for i in n:
		p.rayContainer.addRay()
