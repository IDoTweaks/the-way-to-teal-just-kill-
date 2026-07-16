extends Control
var score = 0;
var targScore = 0
var upEach :float = 0
var gradeFill : float = 0.0
var currentLevel = 1
var tickAccum : float = 0.0
var revealed = false
var revealScale : float = 1.0
@onready var scoreShow = $UI/MainContainer/ScoreShow
@onready var nextBtn = $UI/MainContainer/MenuButtons/nextBtn
@onready var gradeShow = $UI/MainContainer/gradeShow
@onready var gradeFire = $UI/MainContainer/GradeFire
@onready var ui = $UI
func _ready() -> void:
	ui.visible = visible
	set_process(visible)
	visibility_changed.connect(_onVisibilityChanged)

func _onVisibilityChanged() -> void:
	ui.visible = visible
	set_process(visible)
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_forceVisible(ui)

func _setScore(newScore:int):
	targScore = newScore
	upEach = newScore / 2.5
	score = 0
	revealed = false
	revealScale = 1.0
func _setGrade(newGrade: String):
	gradeShow.text = newGrade
	gradeShow.modulate = _gradeColor(newGrade)
	gradeFill = _gradeFill(newGrade)

func _setLevel(lvl):
	currentLevel = lvl
	if Global._hasNextLevel(lvl):
		nextBtn.text = "NEXT LEVEL"
	else:
		nextBtn.text = "MENU"

func _process(delta: float) -> void:
	if targScore > score:
		score += upEach * delta
		if score >= targScore:
			score = targScore
		scoreShow.text = "SCORE\n%d" % int(score)
		tickAccum += delta
		if tickAccum >= 0.05:
			tickAccum = 0.0
			Audio.play("ui_hover", 1.7, -24.0)
	elif !revealed:
		_revealGrade()
	if gradeFire.material:
		gradeFire.material.set_shader_parameter("fill", gradeFill)
	gradeShow.pivot_offset = gradeShow.size / 2.0
	revealScale = lerp(revealScale, 1.0, clamp(delta * 7.0, 0.0, 1.0))
	var throb = 1.0 + 0.08 * gradeFill * (sin(Time.get_ticks_msec() * 0.006) * 0.5 + 0.5)
	gradeShow.scale = Vector2(throb, throb) * revealScale

func _revealGrade():
	revealed = true
	revealScale = 2.6
	if gradeFill >= 1.0:
		Audio.play("win", 1.0, -3.0)
	else:
		Audio.play("pickup", 0.9, -5.0)

func _gradeFill(grade : String) -> float:
	if grade.begins_with("S"):
		return 1.0
	if grade.begins_with("A"):
		return 0.8
	if grade.begins_with("B"):
		return 0.6
	if grade.begins_with("C"):
		return 0.45
	if grade.begins_with("D"):
		return 0.3
	return 0.18

func _gradeColor(grade : String) -> Color:
	if grade.begins_with("S"):
		return Color(1.0, 0.85, 0.1)
	if grade.begins_with("A"):
		return Color(0.15, 1.0, 0.45)
	if grade.begins_with("B"):
		return Color(0.2, 0.65, 1.0)
	if grade.begins_with("C"):
		return Color(0.0, 0.8, 0.7)
	if grade.begins_with("D"):
		return Color(0.6, 0.6, 0.6)
	return Color(1.0, 0.2, 0.2)

func _forceVisible(entity):
	if entity.get_children().size() > 0:
		var children = entity.get_children()
		for child in children:
			_forceVisible(child)
	if entity is CanvasItem:
		entity.visible = true



func _on_quit_btn_button_down() -> void:
	get_tree().quit(6967)


func _on_retry_button_down() -> void:
	Global._goToLevel(currentLevel)


func _on_next_button_down() -> void:
	if Global._hasNextLevel(currentLevel):
		Global._goToLevel(currentLevel + 1)
	else:
		Global._goToLevel(0)
