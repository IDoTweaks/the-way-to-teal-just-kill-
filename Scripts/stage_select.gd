extends Control
signal closed

@onready var stageList : VBoxContainer = $Center/Panel/HBox/StageList
@onready var template : Button = $Center/Panel/HBox/StageList/StageBtnTemplate
@onready var nameLabel : Label = $Center/Panel/HBox/Details/NameLabel
@onready var scoreLabel : Label = $Center/Panel/HBox/Details/ScoreLabel
@onready var timeLabel : Label = $Center/Panel/HBox/Details/TimeLabel
@onready var triesLabel : Label = $Center/Panel/HBox/Details/TriesLabel
@onready var challengesBox : VBoxContainer = $Center/Panel/HBox/Details/ChallengesBox
@onready var playBtn : Button = $Center/Panel/HBox/Details/ButtonRow/PlayBtn
@onready var backBtn : Button = $Center/Panel/HBox/Details/ButtonRow/BackBtn

var selected : int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	template.visible = false
	playBtn.pressed.connect(_onPlay)
	backBtn.pressed.connect(_onBack)
	_buildStages()
	visible = false

func _buildStages() -> void:
	for i in range(1, Global.levels.size()):
		var b : Button = template.duplicate()
		b.visible = true
		var idx := i
		if Global._isUnlocked(i):
			b.text = "LEVEL %d" % i
			b.pressed.connect(func(): _select(idx))
		else:
			b.text = "LEVEL %d  [LOCKED]" % i
			b.disabled = true
			b.modulate = Color(0.45, 0.5, 0.5)
		stageList.add_child(b)

func open() -> void:
	visible = true
	_refresh()

func _select(i : int) -> void:
	selected = i
	_refresh()

func _refresh() -> void:
	nameLabel.text = "LEVEL %d" % selected
	if Global._isUnlocked(selected):
		var bs = Global._ghostScore(selected)
		scoreLabel.text = "BEST SCORE: %s" % (str(bs) if bs >= 0 else "-")
		var bt = Global._bestTime(selected)
		timeLabel.text = "BEST TIME: %s" % (_fmtTime(bt) if bt > 0 else "-")
		triesLabel.text = "TRIES: %d" % Global._tries(selected)
		playBtn.disabled = false
	else:
		scoreLabel.text = "BEST SCORE: LOCKED"
		timeLabel.text = "BEST TIME: LOCKED"
		triesLabel.text = "TRIES: -"
		playBtn.disabled = true
	_refreshChallenges()

func _refreshChallenges() -> void:
	pass

func _fmtTime(t : float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	return "%d:%02d" % [m, s]

func _onPlay() -> void:
	if Global._isUnlocked(selected):
		Global._goToLevel(selected)

func _onBack() -> void:
	visible = false
	closed.emit()
