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
@onready var timeShow = $UI/MainContainer/TimeShow
@onready var recordShow = $UI/MainContainer/RecordShow
@onready var nextBtn = $UI/MainContainer/MenuButtons/nextBtn
@onready var gradeShow = $UI/MainContainer/gradeShow
@onready var gradeFire = $UI/MainContainer/GradeFire
@onready var ui = $UI
@onready var mainContainer = $UI/MainContainer
var storyLbl : Label
func _ready() -> void:
	ui.visible = visible
	set_process(visible)
	visibility_changed.connect(_onVisibilityChanged)
	_buildStoryLine()

func _buildStoryLine() -> void:
	storyLbl = Label.new()
	storyLbl.theme_type_variation = &"Accent"
	storyLbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	storyLbl.offset_left = 180
	storyLbl.offset_right = -180
	storyLbl.offset_top = -244
	storyLbl.offset_bottom = -176
	storyLbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	storyLbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	storyLbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	storyLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	storyLbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	storyLbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	storyLbl.visible = false
	mainContainer.add_child(storyLbl)

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
func _setTime(t : float, par : float, best : float):
	var line = "TIME  %s     PAR  %s" % [_fmtTime(t), _fmtTime(par)]
	if best >= 0.0:
		line += "     BEST  %s" % _fmtTime(best)
	timeShow.text = line
	timeShow.modulate = Color(0.3, 1.0, 0.6) if t <= par else Color(0, 0.85, 0.78)

func _fmtTime(t : float) -> String:
	var s = max(t, 0.0)
	return "%d:%05.2f" % [int(s / 60.0), fmod(s, 60.0)]

func _setRecords(bestTime : bool, bestScore : bool):
	if not bestTime and not bestScore:
		recordShow.visible = false
		return
	if bestTime and bestScore:
		recordShow.text = "NEW RECORD!  TIME + SCORE"
	elif bestTime:
		recordShow.text = "NEW BEST TIME!"
	else:
		recordShow.text = "NEW BEST SCORE!"
	recordShow.visible = true
	recordShow.pivot_offset = recordShow.size / 2.0
	recordShow.scale = Vector2(0.2, 0.2)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(recordShow, "scale", Vector2.ONE, 0.7).set_delay(0.5)
	tw.parallel().tween_callback(func(): Audio.play("win", 1.3, -4.0)).set_delay(0.5)

func _setGrade(newGrade: String):
	gradeShow.text = newGrade
	gradeShow.modulate = _gradeColor(newGrade)
	gradeFill = _gradeFill(newGrade)

func _setLevel(lvl):
	currentLevel = lvl
	_showStoryLine(lvl)
	if Global._hasNextLevel(lvl):
		nextBtn.text = "NEXT LEVEL"
	else:
		nextBtn.text = "MENU"

func _showStoryLine(lvl):
	if storyLbl == null or !is_instance_valid(storyLbl):
		return
	var line = Story._outro(lvl)
	storyLbl.text = line
	storyLbl.visible = line != ""
	if line == "":
		return
	storyLbl.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(storyLbl, "modulate:a", 1.0, 0.6).set_delay(1.2)

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
		Audio.play("ui_click", 0.9, -6.0)

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
