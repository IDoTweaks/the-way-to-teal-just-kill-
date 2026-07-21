extends Node
func _upgrades(): pass

const COMMON = 0
const RARE = 1
const EPIC = 2

const LIST = [
	{"id": "hollow", "name": "HOLLOW POINTS", "desc": "Rifle damage +30%", "tier": COMMON, "cap": 5, "mul": {"damage": 1.3}},
	{"id": "rifling", "name": "MATCH RIFLING", "desc": "Rifle damage +55%", "tier": RARE, "cap": 3, "mul": {"damage": 1.55}},
	{"id": "buckshot", "name": "FAT BUCKSHOT", "desc": "Shotgun damage +30%", "tier": COMMON, "cap": 5, "mul": {"shotGunDmg": 1.3}},
	{"id": "choke", "name": "TIGHT CHOKE", "desc": "Shotgun range falloff starts 60% further", "tier": COMMON, "cap": 3, "mul": {"shotGunFalloffRange": 1.6, "shotGunCloseRange": 1.4}},
	{"id": "slugs", "name": "SOLID SLUGS", "desc": "Shotgun keeps 80% damage at any range", "tier": RARE, "cap": 1, "set": {"shotGunMinDmgMult": 0.8}},
	{"id": "magnum", "name": "MAGNUM LOAD", "desc": "Shotgun damage +60%, fires slower", "tier": RARE, "cap": 3, "mul": {"shotGunDmg": 1.6}, "special": "slowshotgun"},
	{"id": "apround", "name": "AP ROUNDS", "desc": "Sniper damage +40%", "tier": COMMON, "cap": 5, "mul": {"sniperDmg": 1.4}},
	{"id": "boltwork", "name": "SLICK BOLT", "desc": "Sniper cooldown -25%", "tier": COMMON, "cap": 4, "mul": {"sniperCooldown": 0.75}},
	{"id": "railgun", "name": "RAILGUN CORE", "desc": "Sniper damage +120%, cooldown +30%", "tier": EPIC, "cap": 2, "mul": {"sniperDmg": 2.2, "sniperCooldown": 1.3}},
	{"id": "steady", "name": "STEADY HANDS", "desc": "Hipfire spread -35%", "tier": COMMON, "cap": 3, "mul": {"hipfireSpread": 0.65}},
	{"id": "trigger", "name": "LOOSE TRIGGER", "desc": "Fire rate +20%", "tier": RARE, "cap": 4, "special": "firerate"},
	{"id": "overclock", "name": "OVERCLOCKED", "desc": "Fire rate +45%, damage -10%", "tier": EPIC, "cap": 2, "mul": {"damage": 0.9}, "special": "firerate2"},
	{"id": "crit1", "name": "WEAK POINTS", "desc": "+12% critical chance", "tier": COMMON, "cap": 6, "add": {"critChance": 0.12}},
	{"id": "crit2", "name": "EXECUTIONER", "desc": "Criticals deal +75% more", "tier": RARE, "cap": 4, "add": {"critMult": 0.75}},
	{"id": "deadeye", "name": "DEADEYE", "desc": "+25% critical chance", "tier": EPIC, "cap": 3, "add": {"critChance": 0.25}},

	{"id": "vitality", "name": "VITALITY", "desc": "Max health +25", "tier": COMMON, "cap": 6, "special": "maxhp25"},
	{"id": "bulwark", "name": "BULWARK", "desc": "Max health +60, heal to full", "tier": RARE, "cap": 3, "special": "maxhp60"},
	{"id": "bandage", "name": "FIELD DRESSING", "desc": "Heal 40 health now", "tier": COMMON, "cap": 99, "special": "heal40"},
	{"id": "medkit", "name": "FULL MEDKIT", "desc": "Heal to full", "tier": RARE, "cap": 99, "special": "healfull"},
	{"id": "vampire", "name": "VAMPIRIC ROUNDS", "desc": "Heal 4% of damage dealt", "tier": RARE, "cap": 5, "add": {"lifesteal": 0.04}},
	{"id": "harvest", "name": "HARVEST", "desc": "Kills heal +6 health", "tier": COMMON, "cap": 5, "add": {"killHeal": 6.0}},
	{"id": "thorns", "name": "RETALIATION", "desc": "Taking a hit deals 25 damage nearby", "tier": RARE, "cap": 4, "add": {"thorns": 25.0}},
	{"id": "adrenaline", "name": "ADRENALINE", "desc": "Kills heal +12 and restore stamina", "tier": EPIC, "cap": 3, "add": {"killHeal": 12.0}, "special": "killstam"},

	{"id": "sprint", "name": "LIGHT BOOTS", "desc": "Move speed +12%", "tier": COMMON, "cap": 5, "mul": {"upSpeed": 1.12}},
	{"id": "bloodrush", "name": "BLOOD RUSH", "desc": "Move speed +25%", "tier": RARE, "cap": 3, "mul": {"upSpeed": 1.25}},
	{"id": "springs", "name": "COILED LEGS", "desc": "Jump height +15%", "tier": COMMON, "cap": 4, "mul": {"upJump": 1.15}},
	{"id": "doublejump", "name": "SECOND WIND", "desc": "Gain an extra mid-air jump", "tier": EPIC, "cap": 3, "add": {"extraJumps": 1}},
	{"id": "dashpow", "name": "KICK THRUSTERS", "desc": "Dash distance +25%", "tier": COMMON, "cap": 4, "mul": {"dashBoost": 1.25}},
	{"id": "dashcd", "name": "QUICK RECOVERY", "desc": "Dash cooldown -30%", "tier": COMMON, "cap": 4, "mul": {"dashCooldown": 0.7}},
	{"id": "blink", "name": "BLINK DRIVE", "desc": "Dash distance +45%, cooldown -25%", "tier": EPIC, "cap": 2, "mul": {"dashBoost": 1.45, "dashCooldown": 0.75}},
	{"id": "airctrl", "name": "AIR BRAKES", "desc": "Air control +45%", "tier": COMMON, "cap": 4, "mul": {"airAccel": 1.45}},
	{"id": "slick", "name": "SLICK SOLES", "desc": "Slides carry further", "tier": COMMON, "cap": 4, "mul": {"slideFactor": 1.25, "slideDrain": 0.75}},
	{"id": "wallcheap", "name": "GECKO GRIP", "desc": "Wall jumps cost 40% less stamina", "tier": COMMON, "cap": 3, "mul": {"wallJumpCost": 0.6}},

	{"id": "lungs", "name": "BIG LUNGS", "desc": "Stamina regen +35%", "tier": COMMON, "cap": 5, "mul": {"staminaRegen": 1.35}},
	{"id": "quickbreath", "name": "QUICK BREATH", "desc": "Stamina starts regenerating 50% sooner", "tier": COMMON, "cap": 3, "mul": {"staminaDelay": 0.5}},
	{"id": "efficient", "name": "EFFICIENT FORM", "desc": "All stamina costs -20%", "tier": RARE, "cap": 4, "mul": {"upStamCost": 0.8}},
	{"id": "marathon", "name": "MARATHON", "desc": "Stamina regen +60%, costs -15%", "tier": EPIC, "cap": 2, "mul": {"staminaRegen": 1.6, "upStamCost": 0.85}},

	{"id": "slamdmg", "name": "PILEDRIVER", "desc": "Slam damage +50%", "tier": COMMON, "cap": 5, "mul": {"slamDmgPerUnit": 1.5, "slamMaxDmg": 1.5}},
	{"id": "slamcheap", "name": "HEAVY BOOTS", "desc": "Slam costs 50% less stamina", "tier": COMMON, "cap": 3, "mul": {"slamCost": 0.5}},
	{"id": "meteor", "name": "METEOR", "desc": "Slam damage +90% and falls faster", "tier": RARE, "cap": 3, "mul": {"slamDmgPerUnit": 1.9, "slamMaxDmg": 1.9, "slamAccel": 1.4}},
	{"id": "shockwave", "name": "SHOCKWAVE", "desc": "Slam max damage +150", "tier": EPIC, "cap": 3, "add": {"slamMaxDmg": 150.0}},

	{"id": "glasscannon", "name": "GLASS CANNON", "desc": "All weapon damage +70%, max health -30", "tier": EPIC, "cap": 2, "mul": {"damage": 1.7, "shotGunDmg": 1.7, "sniperDmg": 1.7}, "special": "hpdown30"},
	{"id": "berserk", "name": "BERSERKER", "desc": "All weapon damage +35%", "tier": RARE, "cap": 4, "mul": {"damage": 1.35, "shotGunDmg": 1.35, "sniperDmg": 1.35}},
	{"id": "juggernaut", "name": "JUGGERNAUT", "desc": "Max health +100, move speed -8%", "tier": RARE, "cap": 3, "mul": {"upSpeed": 0.92}, "special": "maxhp100"},
	{"id": "featherweight", "name": "FEATHERWEIGHT", "desc": "Speed +18% and jump +10%, max health -15", "tier": RARE, "cap": 3, "mul": {"upSpeed": 1.18, "upJump": 1.1}, "special": "hpdown15"},
	{"id": "cure", "name": "ANTIVENOM", "desc": "Clear all paralysis and resist it", "tier": RARE, "cap": 4, "mul": {"paraChipDmg": 0.6}, "special": "curepara"},
	{"id": "steadycam", "name": "GYRO STOCK", "desc": "Much less recoil and camera roll", "tier": COMMON, "cap": 3, "mul": {"maxRoll": 0.6}, "special": "recoil"},
	{"id": "greed", "name": "GREED", "desc": "Score from rooms +25%", "tier": COMMON, "cap": 6, "special": "score25"},
	{"id": "jackpot", "name": "JACKPOT", "desc": "Score from rooms +60%", "tier": RARE, "cap": 4, "special": "score60"},
	{"id": "scholar", "name": "SCHOLAR", "desc": "See one extra upgrade choice", "tier": EPIC, "cap": 2, "special": "extrachoice"},
]

static func byId(id : String):
	for u in LIST:
		if u["id"] == id:
			return u
	return null

static func roll(rng : RandomNumberGenerator, taken : Dictionary, count : int) -> Array:
	var pool = []
	for u in LIST:
		if taken.get(u["id"], 0) < u["cap"]:
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
