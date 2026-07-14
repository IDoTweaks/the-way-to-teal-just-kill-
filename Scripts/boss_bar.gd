extends CanvasLayer

const PURPLE = Color(0.62, 0.25, 1.0)
const RAGE = Color(0.9, 0.25, 0.3)
const TEAL = Color(0.0, 0.85, 0.72)

var bar : ProgressBar
var label : Label
var fill : StyleBoxFlat
var raging := false

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
	label.text = "THE SNAKE"
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
	if bar:
		bar.value = clamp(frac, 0.0, 1.0)

func _setOpen(open : bool):
	if label == null:
		return
	if open:
		label.text = "THE SNAKE - EXPOSED"
		label.add_theme_color_override("font_color", TEAL)
	else:
		label.text = "THE SNAKE - ENRAGED" if raging else "THE SNAKE"
		label.add_theme_color_override("font_color", RAGE if raging else PURPLE)

func _setRage():
	raging = true
	if label:
		label.text = "THE SNAKE - ENRAGED"
		label.add_theme_color_override("font_color", RAGE)
	if fill:
		fill.bg_color = RAGE
