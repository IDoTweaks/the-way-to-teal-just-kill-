extends CanvasLayer

func _menuTour(): pass

signal finished

const INK = Color(0.03, 0.13, 0.15, 1)
const MINT = Color(0.35, 1, 0.86, 1)
const HILITE = Color(0.35, 1, 0.86, 1)

var steps : Array = []
var idx : int = -1
var target : Control = null

var dim : Control
var ring : Panel
var box : PanelContainer
var label : Label
var stepLabel : Label
var nextBtn : Button
var skipBtn : Button

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	var theme = load("res://UI/funkyTheme.tres")

	dim = ColorRect.new()
	dim.color = Color(0.02, 0.06, 0.07, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var ringStyle = StyleBoxFlat.new()
	ringStyle.bg_color = Color(0, 0, 0, 0)
	ringStyle.set_border_width_all(6)
	ringStyle.border_color = HILITE
	ringStyle.set_corner_radius_all(24)
	ringStyle.corner_detail = 12
	ring = Panel.new()
	ring.add_theme_stylebox_override("panel", ringStyle)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ring)

	box = PanelContainer.new()
	box.theme = theme
	box.custom_minimum_size = Vector2(760, 0)
	add_child(box)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	box.add_child(v)

	stepLabel = Label.new()
	stepLabel.theme_type_variation = "Small"
	v.add_child(stepLabel)

	label = Label.new()
	label.theme_type_variation = "H2"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(700, 0)
	v.add_child(label)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)

	skipBtn = Button.new()
	skipBtn.text = "SKIP TOUR"
	skipBtn.theme_type_variation = "SmallBtn"
	skipBtn.custom_minimum_size = Vector2(220, 54)
	skipBtn.pressed.connect(_finish)
	row.add_child(skipBtn)

	nextBtn = Button.new()
	nextBtn.text = "NEXT"
	nextBtn.theme_type_variation = "BigBtn"
	nextBtn.custom_minimum_size = Vector2(220, 54)
	nextBtn.pressed.connect(_advance)
	row.add_child(nextBtn)

func start(stepList : Array) -> void:
	steps = stepList
	idx = -1
	visible = true
	_advance()

func _advance() -> void:
	idx += 1
	if idx >= steps.size():
		_finish()
		return
	var s = steps[idx]
	if s.has("before") and s["before"] is Callable:
		s["before"].call()
	await get_tree().process_frame
	await get_tree().process_frame
	target = s["target"].call() if s.has("target") and s["target"] is Callable else null
	label.text = s.get("text", "")
	stepLabel.text = "STEP %d / %d" % [idx + 1, steps.size()]
	nextBtn.text = "FINISH" if idx == steps.size() - 1 else "NEXT"
	_place()

func _process(_d : float) -> void:
	if visible and target != null and is_instance_valid(target):
		_place()

func _place() -> void:
	var vp = get_viewport().get_visible_rect().size
	if target != null and is_instance_valid(target) and target.is_visible_in_tree():
		var r = target.get_global_rect()
		var pad = 12.0
		ring.visible = true
		ring.position = r.position - Vector2(pad, pad)
		ring.size = r.size + Vector2(pad, pad) * 2.0
		box.size = Vector2(760, 0)
		var bx = clamp(r.get_center().x - 380.0, 40.0, vp.x - 800.0)
		var by = r.position.y + r.size.y + 40.0
		if by + box.size.y > vp.y - 40.0:
			by = max(40.0, r.position.y - box.size.y - 40.0)
		box.position = Vector2(bx, by)
	else:
		ring.visible = false
		box.size = Vector2(760, 0)
		box.position = Vector2(vp.x * 0.5 - 380.0, vp.y * 0.62)

func _finish() -> void:
	visible = false
	target = null
	finished.emit()
	queue_free()
