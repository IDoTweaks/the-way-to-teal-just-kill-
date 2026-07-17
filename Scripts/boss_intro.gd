extends CanvasLayer

signal done

const TEAL = Color(0, 1, .85)
const RED = Color(1, .15, .3)
const BLUE = Color(.2, .5, 1)

@export var barHeight : float = 110.0
@export var holdTime : float = 1.9
@export var walkTime : float = 1.9
@export var camDist : float = 9.0
@export var camHeight : float = 2.2
@export var camOrbit : float = .35
@export var skipAfter : float = .5

var root : Control
var topBar : ColorRect
var botBar : ColorRect
var flash : ColorRect
var line : ColorRect
var nameMain : Label
var nameRed : Label
var nameBlue : Label
var subLbl : Label
var skipLbl : Label

var font = preload("res://Fonts/Orbitron.tres")
var playing = false
var split : float = 0.0
var nameX : float = 0.0
var elapsed : float = 0.0

var cam : Camera3D
var prevCam : Camera3D
var target : Node3D
var camAngle : float = 0.0
var camPull : float = 0.0

var walkT : float = 0.0
var walkFrom : Vector3
var walkTo : Vector3
var walkHops : int = 0
var walkHeight : float = 2.6
var walking = false

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()

func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	topBar = ColorRect.new()
	topBar.color = Color(0, 0, 0, 1)
	topBar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	topBar.offset_bottom = 0.0
	topBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(topBar)

	botBar = ColorRect.new()
	botBar.color = Color(0, 0, 0, 1)
	botBar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	botBar.offset_top = 0.0
	botBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(botBar)

	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)

	nameRed = _makeName(RED)
	nameBlue = _makeName(BLUE)
	nameMain = _makeName(TEAL)

	line = ColorRect.new()
	line.color = TEAL
	line.set_anchors_preset(Control.PRESET_CENTER)
	line.size = Vector2(0, 3)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(line)

	subLbl = Label.new()
	subLbl.add_theme_font_override("font", font)
	subLbl.add_theme_font_size_override("font_size", 22)
	subLbl.add_theme_color_override("font_color", Color(.75, .95, .92))
	subLbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	subLbl.add_theme_constant_override("outline_size", 6)
	subLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subLbl.set_anchors_preset(Control.PRESET_CENTER)
	subLbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subLbl.modulate.a = 0.0
	root.add_child(subLbl)

	skipLbl = Label.new()
	skipLbl.add_theme_font_override("font", font)
	skipLbl.add_theme_font_size_override("font_size", 14)
	skipLbl.add_theme_color_override("font_color", Color(.6, .7, .7))
	skipLbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	skipLbl.add_theme_constant_override("outline_size", 5)
	skipLbl.text = "PRESS ANY KEY TO SKIP"
	skipLbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skipLbl.offset_left = -260
	skipLbl.offset_top = -40
	skipLbl.offset_right = -24
	skipLbl.offset_bottom = -18
	skipLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skipLbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skipLbl.modulate.a = 0.0
	root.add_child(skipLbl)

func _makeName(col : Color) -> Label:
	var l = Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", 92)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.modulate.a = 0.0
	root.add_child(l)
	return l

func _play(bossName : String, epithet : String, walkTarget : Node3D = null, fromOffset : Vector3 = Vector3.ZERO, hops : int = 0) -> void:
	if playing:
		return
	playing = true
	visible = true
	elapsed = 0.0
	target = walkTarget
	get_tree().paused = true

	if target != null and is_instance_valid(target):
		walkTo = target.global_position
		walkFrom = walkTo + fromOffset
		walkHops = hops
		walkT = 0.0
		walking = fromOffset.length() > .01
		if walking:
			target.global_position = walkFrom
		_makeCam()

	nameMain.text = bossName
	nameRed.text = bossName
	nameBlue.text = bossName
	subLbl.text = epithet
	nameX = 900.0
	split = 52.0
	line.size.x = 0.0
	subLbl.modulate.a = 0.0
	skipLbl.modulate.a = 0.0
	for l in [nameMain, nameRed, nameBlue]:
		l.modulate.a = 0.0

	Audio.play("slam", .42, -1.0)
	Audio.play("enemy_death", .32, -3.0)

	var bars = create_tween()
	bars.set_parallel(true)
	bars.set_trans(Tween.TRANS_EXPO)
	bars.set_ease(Tween.EASE_OUT)
	bars.tween_property(topBar, "offset_bottom", barHeight, .45)
	bars.tween_property(botBar, "offset_top", -barHeight, .45)

	await _wait(walkTime * .55)
	if !playing:
		return
	Audio.play("shotgun", .5, -2.0)
	Audio.play("walljump", .6, -6.0)
	flash.color.a = .5
	var ft = create_tween()
	ft.tween_property(flash, "color:a", 0.0, .35)

	var slide = create_tween()
	slide.set_parallel(true)
	slide.set_trans(Tween.TRANS_QUINT)
	slide.set_ease(Tween.EASE_OUT)
	slide.tween_property(self, "nameX", 0.0, .75)
	slide.tween_property(self, "split", 3.0, .9)
	for l in [nameMain, nameRed, nameBlue]:
		slide.tween_property(l, "modulate:a", 1.0, .2)

	await _wait(.3)
	if !playing:
		return
	var lt = create_tween()
	lt.set_trans(Tween.TRANS_EXPO)
	lt.set_ease(Tween.EASE_OUT)
	lt.tween_property(line, "size:x", 560.0, .4)

	var st = create_tween()
	st.tween_property(subLbl, "modulate:a", 1.0, .35)
	var kt = create_tween()
	kt.tween_property(skipLbl, "modulate:a", 1.0, .4)

	await _wait(holdTime)
	if !playing:
		return
	_exit()

func _makeCam() -> void:
	prevCam = get_viewport().get_camera_3d()
	cam = Camera3D.new()
	cam.process_mode = Node.PROCESS_MODE_ALWAYS
	var host = target.get_parent()
	if host == null:
		host = get_tree().current_scene
	host.add_child(cam)
	camAngle = randf() * TAU
	camPull = 0.0
	_placeCam(0.0)
	cam.make_current()

func _placeCam(t : float) -> void:
	if cam == null or !is_instance_valid(cam) or target == null or !is_instance_valid(target):
		return
	var focus = target.global_position + Vector3(0, 1.4, 0)
	var a = camAngle + t * camOrbit
	var d = camDist + 3.2 * (1.0 - camPull)
	var h = camHeight + 1.4 * (1.0 - camPull)
	cam.global_position = focus + Vector3(cos(a) * d, h, sin(a) * d)
	cam.look_at(focus, Vector3.UP)

func _process(delta : float) -> void:
	if !playing:
		return
	elapsed += delta
	if walking and target != null and is_instance_valid(target):
		walkT = min(walkT + delta / walkTime, 1.0)
		var e = ease(walkT, .45)
		var pos = walkFrom.lerp(walkTo, e)
		if walkHops > 0:
			var arc = abs(sin(e * PI * float(walkHops)))
			pos.y += arc * walkHeight * (1.0 - e * .55)
		target.global_position = pos
		if walkT >= 1.0:
			walking = false
			Audio.play("slam", .9, -4.0)
	camPull = min(camPull + delta / max(walkTime, .01), 1.0)
	_placeCam(elapsed)

	var vw = get_viewport().get_visible_rect().size.x
	for l in [nameMain, nameRed, nameBlue]:
		l.size.x = vw
		l.position.x = -vw * .5 + nameX
		l.position.y = -70
	nameRed.position.x -= split
	nameBlue.position.x += split
	subLbl.size.x = vw
	subLbl.position.x = -vw * .5
	subLbl.position.y = 26
	line.position.x = -line.size.x * .5
	line.position.y = 8

func _unhandled_input(event : InputEvent) -> void:
	if !playing or elapsed < skipAfter:
		return
	if event is InputEventKey and event.pressed and !event.echo:
		get_viewport().set_input_as_handled()
		_skip()
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_skip()

func _exit() -> void:
	Audio.play("ui_click", .7, -8.0)
	var out = create_tween()
	out.set_parallel(true)
	out.set_trans(Tween.TRANS_EXPO)
	out.set_ease(Tween.EASE_IN)
	out.tween_property(self, "nameX", -900.0, .35)
	out.tween_property(topBar, "offset_bottom", 0.0, .4)
	out.tween_property(botBar, "offset_top", 0.0, .4)
	out.tween_property(line, "size:x", 0.0, .3)
	out.tween_property(subLbl, "modulate:a", 0.0, .25)
	out.tween_property(skipLbl, "modulate:a", 0.0, .2)
	for l in [nameMain, nameRed, nameBlue]:
		out.tween_property(l, "modulate:a", 0.0, .3)
	await _wait(.4)
	_finish()

func _skip() -> void:
	if !playing:
		return
	_finish()

func _finish() -> void:
	if !playing:
		return
	playing = false
	visible = false
	if walking and target != null and is_instance_valid(target):
		target.global_position = walkTo
	walking = false
	_restoreCam()
	get_tree().paused = false
	done.emit()

func _restoreCam() -> void:
	if prevCam != null and is_instance_valid(prevCam):
		prevCam.make_current()
	prevCam = null
	if cam != null and is_instance_valid(cam):
		cam.queue_free()
	cam = null

func _wait(t : float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout

func _exit_tree() -> void:
	if playing:
		playing = false
		_restoreCam()
		get_tree().paused = false
