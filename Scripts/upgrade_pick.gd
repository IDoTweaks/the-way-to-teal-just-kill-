extends CanvasLayer
func _upgradePick(): pass

signal picked(upgrade)

const INK = Color(0.031, 0.133, 0.149)
const TEAL = Color(0.0, 0.851, 0.78)
const MINT = Color(0.349, 1.0, 0.859)
const GLOW = Color(0.788, 1.0, 0.961)
const CREAM = Color(1.0, 0.988, 0.941)

var cards : HBoxContainer
var root : Control

func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build():
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = load("res://UI/funkyTheme.tres")
	add_child(root)

	var dim = ColorRect.new()
	dim.color = Color(INK.r, INK.g, INK.b, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 34)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	var title = Label.new()
	title.theme_type_variation = &"Display"
	title.text = "ROOM CLEAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	var sub = Label.new()
	sub.theme_type_variation = &"H2"
	sub.text = "TAKE ONE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(sub)

	cards = HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 26)
	box.add_child(cards)

func open(options : Array):
	for c in cards.get_children():
		c.queue_free()
	for u in options:
		cards.add_child(_makeCard(u))
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	_playIn()

func _menuOpen() -> bool:
	var pm = get_parent().get_node_or_null("PauseMenu")
	return pm != null and pm.isPaused

func _process(_delta: float) -> void:
	if visible and !_menuOpen() and !get_tree().paused:
		get_tree().paused = true

func _tierColor(tier : int) -> Color:
	match tier:
		1: return MINT
		2: return GLOW
	return TEAL

func _tierName(tier : int) -> String:
	match tier:
		1: return "RARE"
		2: return "EPIC"
	return "COMMON"

func _makeCard(u : Dictionary) -> Control:
	var tint = _tierColor(u["tier"])
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(400, 300)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(INK.r + 0.05, INK.g + 0.09, INK.b + 0.1, 0.98)
	sb.border_color = tint
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(26)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 8)
	btn.add_theme_stylebox_override("normal", sb)

	var hov = sb.duplicate()
	hov.bg_color = Color(INK.r + 0.1, INK.g + 0.17, INK.b + 0.18, 1.0)
	hov.border_color = GLOW
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("focus", hov)

	var press = sb.duplicate()
	press.shadow_size = 3
	press.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("pressed", press)

	var col = VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 26
	col.offset_right = -26
	col.offset_top = 24
	col.offset_bottom = -24
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(col)

	var rarity = Label.new()
	rarity.theme_type_variation = &"Small"
	rarity.text = _tierName(u["tier"])
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity.add_theme_color_override("font_color", tint)
	rarity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rarity)

	var name = Label.new()
	name.theme_type_variation = &"H1"
	name.text = u["name"]
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size = Vector2(340, 0)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(name)

	var desc = Label.new()
	desc.text = u["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(340, 0)
	desc.add_theme_color_override("font_color", CREAM)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(desc)

	btn.pressed.connect(_onPick.bind(u))
	return btn

func _playIn():
	var i = 0
	for c in cards.get_children():
		c.modulate.a = 0.0
		c.scale = Vector2(0.85, 0.85)
		c.pivot_offset = c.custom_minimum_size * 0.5
		var tw = create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(c, "modulate:a", 1.0, 0.22).set_delay(i * 0.08)
		tw.tween_property(c, "scale", Vector2.ONE, 0.45).set_delay(i * 0.08).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		i += 1

func _onPick(u : Dictionary):
	Audio.play("win", 1.6, -8.0)
	get_tree().paused = false
	if not OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false
	picked.emit(u)
