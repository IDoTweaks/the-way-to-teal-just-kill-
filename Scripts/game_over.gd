extends CanvasLayer

const INK := Color(0.031, 0.133, 0.149)
const TEAL := Color(0, 0.851, 0.780)
const MINT := Color(0.349, 1, 0.859)
const CREAM := Color(1, 0.988, 0.941)
const DANGER := Color(1, 0.29, 0.31)

var root : Control
var dim : ColorRect
var slash : ColorRect
var titleWrap : Control
var title : Label
var subtitle : Label
var statsRow : HBoxContainer
var buttons : HBoxContainer
var built := false

func _ready() -> void:
	_build()
	visibility_changed.connect(_onVisibilityChanged)
	if visible:
		_playIn()

func _onVisibilityChanged() -> void:
	if visible:
		_refresh()
		_playIn()

func _build() -> void:
	if built:
		return
	built = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = load("res://UI/funkyTheme.tres")
	add_child(root)

	dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(INK.r, INK.g, INK.b, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	slash = ColorRect.new()
	slash.set_anchors_preset(Control.PRESET_FULL_RECT)
	slash.color = Color(DANGER.r, DANGER.g, DANGER.b, 0.0)
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(slash)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 26)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	titleWrap = Control.new()
	titleWrap.custom_minimum_size = Vector2(0, 120)
	titleWrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(titleWrap)

	title = Label.new()
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.theme_type_variation = &"Display"
	title.text = "YOU FUCKING DIED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", DANGER)
	title.add_theme_color_override("font_outline_color", INK)
	title.add_theme_constant_override("outline_size", 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titleWrap.add_child(title)

	subtitle = Label.new()
	subtitle.theme_type_variation = &"H1"
	subtitle.text = "GAME OVER"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", TEAL)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(subtitle)

	statsRow = HBoxContainer.new()
	statsRow.alignment = BoxContainer.ALIGNMENT_CENTER
	statsRow.add_theme_constant_override("separation", 18)
	statsRow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(statsRow)

	buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 22)
	center.add_child(buttons)

	var retry := Button.new()
	retry.theme_type_variation = &"MenuBtn"
	retry.text = "SAME SEED" if Global.endlessRun else "RETRY"
	retry.custom_minimum_size = Vector2(300, 74)
	retry.pressed.connect(_onRetry)
	buttons.add_child(retry)

	if Global.endlessRun:
		var fresh := Button.new()
		fresh.theme_type_variation = &"MenuBtn"
		fresh.text = "NEW RUN"
		fresh.custom_minimum_size = Vector2(300, 74)
		fresh.pressed.connect(_onNewRun)
		buttons.add_child(fresh)

	var menu := Button.new()
	menu.theme_type_variation = &"MenuBtn"
	menu.text = "MENU"
	menu.custom_minimum_size = Vector2(300, 74)
	menu.pressed.connect(_onMenu)
	buttons.add_child(menu)

	var quit := Button.new()
	quit.theme_type_variation = &"MenuBtn"
	quit.text = "QUIT"
	quit.custom_minimum_size = Vector2(300, 74)
	quit.pressed.connect(_onQuit)
	buttons.add_child(quit)

	_refresh()

func _makeTile(label : String, value : String, tint : Color) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(INK.r + 0.05, INK.g + 0.08, INK.b + 0.09, 0.92)
	sb.border_color = tint
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 14
	sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)

	var cap := Label.new()
	cap.theme_type_variation = &"Small"
	cap.text = label
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_color_override("font_color", Color(CREAM.r, CREAM.g, CREAM.b, 0.6))
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cap)

	var val := Label.new()
	val.theme_type_variation = &"H1"
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_color_override("font_color", tint)
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(val)
	return panel

func _refresh() -> void:
	if statsRow == null:
		return
	for c in statsRow.get_children():
		c.queue_free()
	var lvl = Global.currentLevel
	if Global.endlessRun:
		statsRow.add_child(_makeTile("ROOM", "%d" % Global.endlessRoom, TEAL))
		var scoreCap := "SCORE"
		var scoreTint := MINT
		if Global.endlessNewBest:
			scoreCap = "SCORE  ★NEW"
			scoreTint = Color(1.0, 0.85, 0.2)
		statsRow.add_child(_makeTile(scoreCap, "%d" % Global.endlessScore, scoreTint))
		statsRow.add_child(_makeTile("BEST", "%d" % Global.endlessBestScore, DANGER))
		statsRow.add_child(_makeTile("KILLS", "%d" % Global.endlessKills, MINT))
		statsRow.add_child(_makeTile("UPGRADES", "%d" % Global.endlessUpgrades, MINT))
		statsRow.add_child(_makeTile("SEED", "%d" % Global.endlessSeed, CREAM))
		return
	statsRow.add_child(_makeTile("STAGE", Global._levelLabel(lvl), TEAL))
	statsRow.add_child(_makeTile("TIME", _fmtTime(_runTime()), MINT))
	statsRow.add_child(_makeTile("LEFT", "%d" % _enemiesLeft(), DANGER))
	statsRow.add_child(_makeTile("TRY", "#%d" % max(Global._tries(lvl), 1), CREAM))

func _runTime() -> float:
	var p = get_parent()
	if p and "time" in p:
		return p.time
	return 0.0

func _enemiesLeft() -> int:
	return get_tree().get_nodes_in_group("enemies").size()

func _fmtTime(t : float) -> String:
	var s = max(t, 0.0)
	return "%d:%05.2f" % [int(s / 60.0), fmod(s, 60.0)]

func _playIn() -> void:
	if root == null:
		return
	dim.color.a = 0.0
	slash.color.a = 0.0
	title.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	statsRow.modulate.a = 0.0
	buttons.modulate.a = 0.0
	await get_tree().process_frame
	if not is_inside_tree() or not visible:
		return
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2(2.6, 2.6)
	title.rotation = deg_to_rad(-7.0)
	title.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	statsRow.modulate.a = 0.0
	statsRow.pivot_offset = statsRow.size / 2.0
	statsRow.scale = Vector2(0.86, 0.86)
	buttons.modulate.a = 0.0

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "color:a", 0.88, 0.28)
	tw.tween_property(slash, "color:a", 0.42, 0.07)
	tw.chain().tween_property(slash, "color:a", 0.0, 0.35)

	var t2 = create_tween()
	t2.set_parallel(true)
	t2.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t2.tween_property(title, "scale", Vector2.ONE, 0.42)
	t2.tween_property(title, "rotation", 0.0, 0.42)
	t2.tween_property(title, "modulate:a", 1.0, 0.18)

	var t3 = create_tween()
	t3.tween_interval(0.30)
	t3.tween_property(subtitle, "modulate:a", 1.0, 0.22)

	var t4 = create_tween()
	t4.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t4.tween_interval(0.42)
	t4.set_parallel(true)
	t4.tween_property(statsRow, "modulate:a", 1.0, 0.26)
	t4.tween_property(statsRow, "scale", Vector2.ONE, 0.34)

	var t5 = create_tween()
	t5.tween_interval(0.62)
	t5.tween_property(buttons, "modulate:a", 1.0, 0.26)

func _onRetry() -> void:
	Global._restartCurrent()

func _onNewRun() -> void:
	Global._goToEndless(randi())

func _onMenu() -> void:
	Global._goToLevel(0)

func _onQuit() -> void:
	get_tree().quit(6967)
