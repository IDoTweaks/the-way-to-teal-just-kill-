extends CanvasLayer

const PURPLE = Color(0.62, 0.25, 1.0)
const DEEP = Color(0.45, 0.05, 0.85)
const TEAL = Color(0.0, 0.85, 0.72)
const DANGER = Color(1.0, 0.25, 0.3)

const LEVELS = [
	["1", "DASH GOES FLAT - no lift, half the distance"],
	["2", "DASH DEAD - nothing happens"],
	["3", "NO SLIDE, NO SLAM"],
	["4", "NO WALL-JUMP"],
	["5", "JUMP HEIGHT -40%"],
	["6", "NO AIR CONTROL - a jump is a commitment"],
	["7", "SPEED -40%"],
	["8", "NO JUMP AT ALL"],
	["9", "SPEED -75%, and you start bleeding out"],
	["10", "YOU DIE."],
]

@export var armTime : float = 1.2
var armed : bool = false
var btn : Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	Audio.play("player_hurt", 0.5, -8.0)
	await get_tree().create_timer(armTime, true, false, true).timeout
	_arm()

func _build() -> void:
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var frame = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.0, 0.07, 0.98)
	style.border_color = PURPLE
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(26)
	style.shadow_color = Color(DEEP.r, DEEP.g, DEEP.b, 0.45)
	style.shadow_size = 18
	frame.add_theme_stylebox_override("panel", style)
	center.add_child(frame)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	frame.add_child(box)

	var title = Label.new()
	title.text = "PARALYSIS"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", PURPLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub = Label.new()
	sub.text = "THE SNAKE'S VENOM. EVERY HIT ADDS A LEVEL.\nIT DOES NOT WEAR OFF ON ITS OWN."
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.75, 0.7, 0.85))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	box.add_child(_rule())

	for lvl in LEVELS:
		box.add_child(_row(lvl[0], lvl[1]))

	box.add_child(_rule())

	var cure = Label.new()
	cure.text = "BURN A LEVEL OFF AT A CURE DROP - IT COSTS HEALTH."
	cure.add_theme_font_size_override("font_size", 15)
	cure.add_theme_color_override("font_color", TEAL)
	cure.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cure)

	btn = Button.new()
	btn.text = "READ IT"
	btn.disabled = true
	btn.custom_minimum_size = Vector2(240, 44)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.5, 0.45, 0.6))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.5))
	btn.pressed.connect(_dismiss)
	var holder = CenterContainer.new()
	holder.add_child(btn)
	box.add_child(holder)

func _rule() -> Control:
	var line = ColorRect.new()
	line.color = Color(DEEP.r, DEEP.g, DEEP.b, 0.6)
	line.custom_minimum_size = Vector2(0, 2)
	return line

func _row(num : String, effect : String) -> Control:
	var lvl = int(num)
	var heat = float(lvl - 1) / float(LEVELS.size() - 1)
	var tint = PURPLE.lerp(DANGER, heat)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var chip = Label.new()
	chip.text = num
	chip.custom_minimum_size = Vector2(46, 0)
	chip.add_theme_font_size_override("font_size", 22)
	chip.add_theme_color_override("font_color", tint)
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(chip)

	var txt = Label.new()
	txt.text = effect
	txt.add_theme_font_size_override("font_size", 18)
	txt.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95).lerp(DANGER, heat * 0.55))
	txt.custom_minimum_size = Vector2(430, 0)
	row.add_child(txt)
	return row

func _arm() -> void:
	if btn == null or !is_instance_valid(btn):
		return
	armed = true
	btn.disabled = false
	btn.text = "UNDERSTOOD"
	btn.add_theme_color_override("font_color", TEAL)
	btn.grab_focus()
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(btn, "modulate:a", 0.55, 0.6)
	tw.tween_property(btn, "modulate:a", 1.0, 0.6)

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		return
	if !armed:
		return
	if event is InputEventKey and event.pressed and !event.echo:
		_dismiss()

func _dismiss() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
