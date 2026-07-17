extends CanvasLayer

const PURPLE = Color(0.62, 0.25, 1.0)
const RAGE = Color(0.9, 0.25, 0.3)
const TEAL = Color(0.0, 0.85, 0.72)

var bar : ProgressBar
var label : Label
var fill : StyleBoxFlat
var raging := false
var barTween : Tween
var rageTween : Tween
var bossName := "THE SNAKE"
var statusTween : Tween

func _ready() -> void:
	layer = 50
	_build()

func _build() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.offset_left = 280
	box.offset_right = -280
	box.offset_top = 22
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 5)
	root.add_child(box)

	label = Label.new()
	label.text = bossName
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", PURPLE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)

	var back = StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.05, 0.06, 0.9)
	back.border_color = PURPLE
	back.set_border_width_all(2)

	fill = StyleBoxFlat.new()
	fill.bg_color = PURPLE

	bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = 1.0
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)

func _setHealth(frac : float):
	if bar == null:
		return
	if barTween:
		barTween.kill()
	barTween = create_tween()
	barTween.set_trans(Tween.TRANS_CUBIC)
	barTween.set_ease(Tween.EASE_OUT)
	barTween.tween_property(bar, "value", clamp(frac, 0.0, 1.0), .25)

func _setName(n : String):
	bossName = n
	if label:
		label.text = bossName

func _setStatus(txt : String, col : Color, pulse : bool = false):
	if label == null:
		return
	label.text = bossName if txt == "" else bossName + " - " + txt
	label.add_theme_color_override("font_color", col)
	if statusTween:
		statusTween.kill()
	if !pulse:
		label.modulate.a = 1.0
		return
	statusTween = create_tween()
	statusTween.set_loops()
	statusTween.tween_property(label, "modulate:a", .35, .28)
	statusTween.tween_property(label, "modulate:a", 1.0, .28)

func _setOpen(open : bool):
	if open:
		_setStatus("EXPOSED", TEAL)
	else:
		_setStatus("ENRAGED" if raging else "", RAGE if raging else PURPLE)

func _setRage():
	raging = true
	_setStatus("ENRAGED", RAGE)
	if fill:
		fill.bg_color = RAGE
	if rageTween:
		rageTween.kill()
	rageTween = create_tween()
	rageTween.set_trans(Tween.TRANS_SINE)
	for i in 3:
		rageTween.tween_method(func(v): fill.bg_color = RAGE.lerp(Color.WHITE, v), 0.0, 1.0, .09)
		rageTween.tween_method(func(v): fill.bg_color = Color.WHITE.lerp(RAGE, v), 0.0, 1.0, .09)
