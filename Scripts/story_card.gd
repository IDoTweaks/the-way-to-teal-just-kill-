extends CanvasLayer

signal done

func _storyCard(): pass

const TEAL = Color(0.35, 1.0, 0.86)
const TEXT = Color(1.0, 0.99, 0.94)
const DIM = Color(0.6, 0.84, 0.82)
const INK = Color(0.031, 0.133, 0.149)

@export var charTime : float = 0.018
@export var armTime : float = 0.35

var lines : Array = []
var idx : int = 0
var shown : int = 0
var revealT : float = 0.0
var revealing : bool = false
var armed : bool = false
var finishing : bool = false

var back : ColorRect
var frame : PanelContainer
var chapLbl : Label
var titleLbl : Label
var whoLbl : Label
var lineLbl : Label
var promptLbl : Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	visible = false

func _play(levelIdx : int, title : String, storyLines : Array) -> void:
	lines = storyLines
	if lines.is_empty():
		_dismiss()
		return
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	chapLbl.text = "CHAPTER %d" % levelIdx
	titleLbl.text = title
	visible = true
	back.color.a = 0.0
	frame.modulate.a = 0.0
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(back, "color:a", 0.96, 0.3)
	tw.tween_property(frame, "modulate:a", 1.0, 0.3)
	Audio.play("ui_click", 0.7, -8.0)
	await get_tree().create_timer(armTime, true, false, true).timeout
	armed = true
	_showLine()

func _build() -> void:
	back = ColorRect.new()
	back.color = Color(0.02, 0.02, 0.03, 0.0)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(back)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.theme = load("res://UI/funkyTheme.tres")
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	frame = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.19, 0.22, 1)
	style.border_color = TEAL
	style.set_border_width_all(6)
	style.set_corner_radius_all(28)
	style.corner_detail = 12
	style.set_content_margin_all(34)
	frame.add_theme_stylebox_override("panel", style)
	frame.custom_minimum_size = Vector2(1020, 0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(frame)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	frame.add_child(box)

	chapLbl = Label.new()
	chapLbl.add_theme_font_size_override("font_size", 20)
	chapLbl.add_theme_color_override("font_color", DIM)
	box.add_child(chapLbl)

	titleLbl = Label.new()
	titleLbl.add_theme_font_size_override("font_size", 68)
	titleLbl.add_theme_color_override("font_color", TEAL)
	box.add_child(titleLbl)

	var rule = ColorRect.new()
	rule.color = TEAL
	rule.custom_minimum_size = Vector2(0, 4)
	box.add_child(rule)

	box.add_child(_gap(20))

	whoLbl = Label.new()
	whoLbl.add_theme_font_size_override("font_size", 22)
	whoLbl.add_theme_color_override("font_color", TEAL)
	box.add_child(whoLbl)

	lineLbl = Label.new()
	lineLbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lineLbl.custom_minimum_size = Vector2(0, 116)
	lineLbl.add_theme_font_size_override("font_size", 30)
	lineLbl.add_theme_color_override("font_color", TEXT)
	box.add_child(lineLbl)

	box.add_child(_gap(14))

	promptLbl = Label.new()
	promptLbl.add_theme_font_size_override("font_size", 18)
	promptLbl.add_theme_color_override("font_color", DIM)
	promptLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	promptLbl.text = "CLICK OR PRESS SPACE"
	box.add_child(promptLbl)

func _gap(h : int) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, h)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer

func _showLine() -> void:
	var entry = lines[idx]
	whoLbl.text = str(entry[0])
	lineLbl.text = ""
	shown = 0
	revealT = 0.0
	revealing = true
	promptLbl.text = "CLICK OR PRESS SPACE TO SKIP"

func _fullLine() -> String:
	return str(lines[idx][1])

func _process(delta : float) -> void:
	if !revealing:
		return
	var full = _fullLine()
	revealT += delta
	while revealT >= charTime and shown < full.length():
		revealT -= charTime
		shown += 1
		if shown % 3 == 0:
			Audio.play("ui_hover", 1.9, -30.0)
	lineLbl.text = full.substr(0, shown)
	if shown >= full.length():
		revealing = false
		promptLbl.text = "CLICK OR PRESS SPACE" if idx + 1 < lines.size() else "CLICK OR PRESS SPACE TO BEGIN"

func _advance() -> void:
	if !armed or finishing:
		return
	if revealing:
		revealing = false
		shown = _fullLine().length()
		lineLbl.text = _fullLine()
		promptLbl.text = "CLICK OR PRESS SPACE" if idx + 1 < lines.size() else "CLICK OR PRESS SPACE TO BEGIN"
		return
	idx += 1
	if idx >= lines.size():
		_dismiss()
		return
	Audio.play("ui_click", 1.1, -14.0)
	_showLine()

func _input(event : InputEvent) -> void:
	if finishing:
		return
	if event is InputEventKey and event.pressed and !event.echo:
		get_viewport().set_input_as_handled()
		_advance()
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_advance()

func _dismiss() -> void:
	if finishing:
		return
	finishing = true
	revealing = false
	if back != null and is_instance_valid(back):
		var tw = create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(back, "color:a", 0.0, 0.25)
		tw.tween_property(frame, "modulate:a", 0.0, 0.25)
		await tw.finished
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	done.emit()
	queue_free()

func _exit_tree() -> void:
	if !finishing:
		get_tree().paused = false
