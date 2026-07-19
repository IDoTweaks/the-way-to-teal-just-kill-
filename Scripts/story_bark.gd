extends CanvasLayer

func _storyBark(): pass

const TEAL = Color(0.35, 1.0, 0.86)
const TEXT = Color(1.0, 0.99, 0.94)
const INK = Color(0.031, 0.133, 0.149)

@export var holdBase : float = 1.9
@export var holdPerChar : float = 0.042
@export var holdMax : float = 6.0

var barks : Array = []
var fired : Array = []
var queue : Array = []
var running : bool = false
var stopped : bool = false
var elapsed : float = 0.0
var baseEnemies : int = 0
var showing : bool = false

var frame : PanelContainer
var whoLbl : Label
var lineLbl : Label

func _ready() -> void:
	layer = 55
	_build()
	if Story != null:
		Story.levelEnded.connect(_stop)

func _build() -> void:
	frame = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.07, 0.08, 0.82)
	style.border_color = TEAL
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.corner_detail = 10
	style.set_content_margin_all(16)
	frame.add_theme_stylebox_override("panel", style)
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 1.0
	frame.anchor_bottom = 1.0
	frame.offset_left = -430
	frame.offset_right = 430
	frame.offset_top = -230
	frame.offset_bottom = -140
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.modulate.a = 0.0
	frame.visible = false
	add_child(frame)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(box)

	whoLbl = Label.new()
	whoLbl.add_theme_font_override("font", load("res://Fonts/LilitaOne.tres"))
	whoLbl.add_theme_font_size_override("font_size", 18)
	whoLbl.add_theme_color_override("font_color", TEAL)
	whoLbl.add_theme_color_override("font_outline_color", INK)
	whoLbl.add_theme_constant_override("outline_size", 5)
	whoLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	whoLbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(whoLbl)

	lineLbl = Label.new()
	lineLbl.add_theme_font_override("font", load("res://Fonts/LilitaOne.tres"))
	lineLbl.add_theme_font_size_override("font_size", 26)
	lineLbl.add_theme_color_override("font_color", TEXT)
	lineLbl.add_theme_color_override("font_outline_color", INK)
	lineLbl.add_theme_constant_override("outline_size", 7)
	lineLbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lineLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lineLbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(lineLbl)

func _load(data : Array) -> void:
	barks = data
	fired.resize(barks.size())
	fired.fill(false)

func _begin() -> void:
	if stopped:
		return
	elapsed = 0.0
	baseEnemies = get_tree().get_nodes_in_group("enemies").size()
	running = true

func _stop() -> void:
	stopped = true
	running = false
	queue.clear()

func _killedFrac() -> float:
	if baseEnemies <= 0:
		return 0.0
	var alive = get_tree().get_nodes_in_group("enemies").size()
	return clamp(float(baseEnemies - alive) / float(baseEnemies), 0.0, 1.0)

func _process(delta : float) -> void:
	if running:
		elapsed += delta
		var frac = _killedFrac()
		for i in barks.size():
			if fired[i]:
				continue
			var b = barks[i]
			var hit = false
			if b.has("at"):
				hit = elapsed >= float(b["at"])
			elif b.has("frac"):
				hit = baseEnemies > 0 and frac >= float(b["frac"])
			if hit:
				fired[i] = true
				queue.append(b)
	if !showing and !queue.is_empty():
		_show(queue.pop_front())

func _show(b) -> void:
	showing = true
	whoLbl.text = str(b.get("who", ""))
	lineLbl.text = str(b.get("line", ""))
	frame.visible = true
	frame.modulate.a = 0.0
	frame.offset_top = -214
	frame.offset_bottom = -124
	Audio.play("ui_hover", 1.3, -22.0)
	var hold = clamp(holdBase + lineLbl.text.length() * holdPerChar, holdBase, holdMax)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_QUINT)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(frame, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(frame, "offset_top", -230.0, 0.3)
	tw.parallel().tween_property(frame, "offset_bottom", -140.0, 0.3)
	tw.tween_interval(hold)
	tw.tween_property(frame, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_hide)

func _hide() -> void:
	frame.visible = false
	showing = false
