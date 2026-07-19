extends Node

signal levelEnded

const LANDLORD = "THE LANDLORD"
const SNAKE = "THE SNAKE, ESQ."
const DESK = "RECEPTION"
const SYSTEM = "SNEK & CO."
const YOU = "YOU"

const CHAPTERS = {
	1: {
		"title": "THE NOTICE",
		"card": [
			[LANDLORD, "morning. don't get comfortable, this won't take long."],
			[LANDLORD, "your lease is terminated. reason code 4: colour."],
			[YOU, "...that's a reason code?"],
			[LANDLORD, "it's a very popular one. out you go."],
		],
		"barks": [
			{"at": 4.0, "who": LANDLORD, "line": "the green ones can stay. that's the whole policy, really."},
			{"frac": 0.5, "who": LANDLORD, "line": "oh, you're going to be DIFFICULT about it."},
			{"frac": 1.0, "who": YOU, "line": "who writes the reason codes."},
		],
		"outro": "somewhere above the green world, a form is filed about you.",
	},
	2: {
		"title": "THE LOBBY",
		"card": [
			[SYSTEM, "welcome to SNEK & CO. venom management. please be green."],
			[DESK, "appeals are handled on the ninth floor."],
			[YOU, "great. how do i get to the ninth floor?"],
			[DESK, "you'd need to be a tenant. you're not a tenant anymore."],
		],
		"barks": [
			{"at": 3.5, "who": DESK, "line": "sir. SIR. you cannot appeal in the lobby."},
			{"frac": 0.4, "who": SYSTEM, "line": "security is a valued part of the SNEK & CO. family."},
			{"frac": 1.0, "who": DESK, "line": "i'm going to have to note this in your file."},
		],
		"outro": "reception has noted it in your file.",
	},
	3: {
		"title": "FILING",
		"card": [
			[SYSTEM, "you are now case 0-0-4-1-B. congratulations on your case number."],
			[YOU, "i had a name."],
			[SYSTEM, "the name is in the file. the file is on the floor. keep up."],
		],
		"barks": [
			{"at": 3.0, "who": SYSTEM, "line": "please do not shoot the filing. the filing is load-bearing."},
			{"frac": 0.5, "who": SNAKE, "line": "hm. someone's reading their own paperwork. that's new."},
			{"frac": 1.0, "who": YOU, "line": "there's a whole cabinet of us."},
		],
		"outro": "case 0-0-4-1-B is one of eleven thousand.",
	},
	4: {
		"title": "THE FLOOR",
		"card": [
			[SNAKE, "ah — you've reached the working floor. mind them, they're mine."],
			[SNAKE, "they didn't write the policy either. they just process it."],
			[YOU, "then they should move."],
			[SNAKE, "with what savings, blue man?"],
		],
		"barks": [
			{"at": 4.0, "who": SNAKE, "line": "that one has a family. i sign the cards myself."},
			{"frac": 0.6, "who": SNAKE, "line": "you'll notice none of them chose you as an enemy."},
			{"frac": 1.0, "who": YOU, "line": "i didn't choose it either."},
		],
		"outro": "none of them wrote the policy. all of them enforced it.",
	},
	5: {
		"title": "ABOVE THE LINE",
		"card": [
			[SNAKE, "let's stop wasting each other's afternoon. i have an offer."],
			[SNAKE, "a badge. a desk. green-adjacent status, provisionally."],
			[SNAKE, "you'd be the exception. everyone loves being the exception."],
			[YOU, "and the rule stays."],
			[SNAKE, "the rule is the product."],
		],
		"barks": [
			{"at": 4.5, "who": SNAKE, "line": "the badge comes with dental. i'm being serious."},
			{"frac": 0.5, "who": SNAKE, "line": "declining is also an answer. a loud one."},
			{"frac": 1.0, "who": SNAKE, "line": "noted. withdrawn."},
		],
		"outro": "you declined the badge. it goes in the file too.",
	},
	6: {
		"title": "THE VAULT",
		"card": [
			[SYSTEM, "restricted. pigment control. authorised staff only."],
			[YOU, "...it's teal. you keep it in a VAULT."],
			[SNAKE, "we ration it. scarcity is what makes it worth something."],
			[SNAKE, "if everyone could be teal, nobody would pay to be green."],
		],
		"barks": [
			{"at": 4.0, "who": SNAKE, "line": "careful with the barrels. that's four quarters of margin."},
			{"frac": 0.5, "who": YOU, "line": "there's enough here for everyone."},
			{"frac": 1.0, "who": SNAKE, "line": "yes. that was always the problem."},
		],
		"outro": "there was always enough. that was the secret.",
	},
	7: {
		"title": "LEGAL",
		"card": [
			[SNAKE, "before you go further — read clause nine. humour me."],
			[YOU, "'occupancy is provisional and may be revoked without cause.'"],
			[SNAKE, "every lease. every tenant. green ones too."],
			[SNAKE, "you were never being singled out. you were just first."],
		],
		"barks": [
			{"at": 4.0, "who": SNAKE, "line": "i evict everyone eventually. you were simply easiest to start with."},
			{"frac": 0.5, "who": YOU, "line": "they don't know."},
			{"frac": 1.0, "who": SNAKE, "line": "they don't read. it's the same thing, commercially."},
		],
		"outro": "clause nine applies to the whole green world.",
	},
	8: {
		"title": "THE ASCENT",
		"card": [
			[SNAKE, "no more forms. no more offers. i'd like that on the record."],
			[SNAKE, "from here it's just stairs and men who are paid to be on them."],
			[YOU, "good."],
		],
		"barks": [
			{"at": 3.5, "who": SNAKE, "line": "you're making very good time. i mean that as a threat."},
			{"frac": 0.6, "who": SNAKE, "line": "the ninth floor was never for appeals, by the way."},
			{"frac": 1.0, "who": SNAKE, "line": "it's where i sit."},
		],
		"outro": "eight floors down. one door left.",
	},
	9: {
		"title": "TOP FLOOR",
		"card": [
			[SNAKE, "ninth floor. appeals department. you made it after all."],
			[SNAKE, "i'll be honest, blue man — i respect the commute."],
			[SNAKE, "come in. i'll get the door. i always get the door."],
		],
		"barks": [
			{"at": 3.5, "who": SNAKE, "line": "the carpet is new. try."},
			{"frac": 0.5, "who": SNAKE, "line": "you understand this doesn't change the policy."},
			{"frac": 1.0, "who": SNAKE, "line": "the policy is downstairs. i'm up here."},
		],
		"outro": "the door is open. it was never locked.",
	},
	10: {
		"title": "THE MAN WHO SIGNED",
		"card": [
			[SNAKE, "so. no badge, no lease, no case number you'll answer to."],
			[SNAKE, "you know the worst part? i don't hate you. i've never hated anyone."],
			[SNAKE, "hating you would have cost me money."],
			[YOU, "you signed it."],
			[SNAKE, "i signed all of it. that's the job. shall we?"],
		],
		"barks": [],
		"outro": "",
	},
}

func _story(): pass

func _chapter(idx):
	return CHAPTERS.get(idx, {})

func _title(idx) -> String:
	return _chapter(idx).get("title", "")

func _seen(idx) -> bool:
	return Global.storySeen.get(idx, false)

func _markSeen(idx) -> void:
	Global.storySeen[idx] = true
	Global._localSave()

func _outro(idx) -> String:
	return _chapter(idx).get("outro", "")

func _endLevel() -> void:
	levelEnded.emit()

func _spawn(host : Node, idx : int, after : Callable = Callable()) -> void:
	var ch = _chapter(idx)
	if ch.is_empty():
		if after.is_valid():
			after.call()
		return
	var barker = CanvasLayer.new()
	barker.set_script(preload("res://Scripts/story_bark.gd"))
	host.add_child(barker)
	barker._load(ch.get("barks", []))
	if _seen(idx):
		barker._begin()
		if after.is_valid():
			after.call()
		return
	var card = CanvasLayer.new()
	card.set_script(preload("res://Scripts/story_card.gd"))
	host.add_child(card)
	card.done.connect(barker._begin)
	if after.is_valid():
		card.done.connect(after)
	_markSeen(idx)
	card._play(idx, ch.get("title", ""), ch.get("card", []))
