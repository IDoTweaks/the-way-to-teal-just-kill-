extends CanvasLayer

signal done

const TEAL = Color(0, 1, .85)
const RED = Color(1, .15, .3)
const BLUE = Color(.2, .5, 1)

@export var barHeight : float = 110.0
@export var holdTime : float = 1.9
@export var walkTime : float = 1.9
@export var camDist : float = 7.0
@export var camHeight : float = 2.2
@export var camFocus : float = 1.4
@export var camOrbit : float = .35
@export var skipAfter : float = .5
@export var titleY : float = .70
@export var camSide : float = .7

var root : Control
var topBar : ColorRect
var botBar : ColorRect
var flash : ColorRect
var scrim : ColorRect
var band : ColorRect
var bandMat : ShaderMaterial
var line : ColorRect
var nameMain : Label
var nameRed : Label
var nameBlue : Label
var subLbl : Label
var skipLbl : Label

var font = preload("res://Fonts/Orbitron.tres")
var titleShader = preload("res://shaders/bossTitle.gdshader")
var nameFont : FontVariation
var subFont : FontVariation
var playing = false
var split : float = 0.0
var nameX : float = 0.0
var punch : float = 1.0
var jitter : float = 0.0
var elapsed : float = 0.0
var hidden : Array = []

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
	nameFont = FontVariation.new()
	nameFont.base_font = font
	nameFont.spacing_glyph = 7
	subFont = FontVariation.new()
	subFont.base_font = font
	subFont.spacing_glyph = 11

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	scrim = ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0, 0, 0, 0)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)

	bandMat = ShaderMaterial.new()
	bandMat.shader = titleShader
	bandMat.set_shader_parameter("edgeCol", TEAL)
	bandMat.set_shader_parameter("reveal", -0.2)
	bandMat.set_shader_parameter("glitch", 0.0)
	bandMat.set_shader_parameter("fade", 1.0)

	band = ColorRect.new()
	band.material = bandMat
	band.set_anchors_preset(Control.PRESET_TOP_LEFT)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(band)

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
	line.set_anchors_preset(Control.PRESET_TOP_LEFT)
	line.size = Vector2(0, 3)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(line)

	subLbl = Label.new()
	subLbl.add_theme_font_override("font", subFont)
	subLbl.add_theme_font_size_override("font_size", 22)
	subLbl.add_theme_color_override("font_color", Color(.75, .95, .92))
	subLbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	subLbl.add_theme_constant_override("outline_size", 6)
	subLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subLbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
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
	l.add_theme_font_override("font", nameFont)
	l.add_theme_font_size_override("font_size", 104)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, .85))
	l.add_theme_constant_override("shadow_offset_x", 5)
	l.add_theme_constant_override("shadow_offset_y", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_TOP_LEFT)
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
	nameX = 620.0
	split = 64.0
	punch = 1.28
	jitter = 0.0
	line.size.x = 0.0
	subLbl.modulate.a = 0.0
	skipLbl.modulate.a = 0.0
	scrim.color.a = 0.0
	bandMat.set_shader_parameter("reveal", -0.2)
	bandMat.set_shader_parameter("glitch", 0.0)
	bandMat.set_shader_parameter("fade", 1.0)
	for l in [nameMain, nameRed, nameBlue]:
		l.modulate.a = 0.0

	_hideHud()

	Audio.play("slam", .42, -1.0)
	Audio.play("enemy_death", .32, -3.0)

	var bars = create_tween()
	bars.set_parallel(true)
	bars.set_trans(Tween.TRANS_EXPO)
	bars.set_ease(Tween.EASE_OUT)
	bars.tween_property(topBar, "offset_bottom", barHeight, .45)
	bars.tween_property(botBar, "offset_top", -barHeight, .45)
	bars.tween_property(scrim, "color:a", .34, .6)

	await _wait(walkTime * .4)
	if !playing:
		return
	Audio.play("dash", .55, -8.0)
	var bt = create_tween()
	bt.set_trans(Tween.TRANS_QUINT)
	bt.set_ease(Tween.EASE_OUT)
	bt.tween_property(bandMat, "shader_parameter/reveal", 1.35, .55)

	await _wait(walkTime * .15)
	if !playing:
		return
	Audio.play("shotgun", .5, -2.0)
	Audio.play("walljump", .6, -6.0)
	flash.color.a = .5
	var ft = create_tween()
	ft.tween_property(flash, "color:a", 0.0, .35)

	jitter = 16.0
	bandMat.set_shader_parameter("glitch", 1.0)
	var gt = create_tween()
	gt.set_parallel(true)
	gt.tween_property(self, "jitter", 0.0, .5)
	gt.tween_property(bandMat, "shader_parameter/glitch", 0.0, .5)

	var slide = create_tween()
	slide.set_parallel(true)
	slide.set_trans(Tween.TRANS_QUINT)
	slide.set_ease(Tween.EASE_OUT)
	slide.tween_property(self, "nameX", 0.0, .75)
	slide.tween_property(self, "split", 4.0, .9)
	slide.tween_property(self, "punch", 1.0, .55).set_trans(Tween.TRANS_BACK)
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
	camAngle = _pickAngle()
	camPull = 0.0
	_placeCam(0.0)
	cam.make_current()

func _findPlayer() -> Node3D:
	if target != null and "player" in target and target.player is Node3D:
		return target.player
	for n in get_tree().root.find_children("*", "CharacterBody3D", true, false):
		if n.has_method("player"):
			return n
	return null

func _pickAngle() -> float:
	var pl = _findPlayer()
	if pl == null or !is_instance_valid(pl):
		return randf() * TAU
	var toPl = pl.global_position - walkTo
	toPl.y = 0
	if toPl.length() < .5:
		return randf() * TAU
	return atan2(toPl.z, toPl.x) + camSide

func _placeCam(t : float) -> void:
	if cam == null or !is_instance_valid(cam) or target == null or !is_instance_valid(target):
		return
	var focus = target.global_position + Vector3(0, camFocus, 0)
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

	var vs = get_viewport().get_visible_rect().size
	var vw = vs.x
	var cy = vs.y * titleY

	band.size = Vector2(vw, 236)
	band.position = Vector2(0, cy - 128)

	for l in [nameMain, nameRed, nameBlue]:
		l.size.x = vw
		l.pivot_offset = Vector2(vw * .5, l.size.y * .5)
		l.scale = Vector2(punch, punch)
		l.position = Vector2(nameX, cy - 112)
	nameRed.position.x -= split
	nameBlue.position.x += split
	if jitter > .01:
		nameRed.position.x += randf_range(-jitter, jitter)
		nameBlue.position.x += randf_range(-jitter, jitter)
		nameMain.position.y += randf_range(-jitter, jitter) * .35

	line.position = Vector2(vw * .5 - line.size.x * .5, cy + 30)
	subLbl.size.x = vw
	subLbl.position = Vector2(0, cy + 44)

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
	out.tween_property(scrim, "color:a", 0.0, .35)
	out.tween_property(bandMat, "shader_parameter/fade", 0.0, .3)
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
	_showHud()
	get_tree().paused = false
	done.emit()

func _hideHud() -> void:
	hidden.clear()
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if n == self or n.layer >= 100 or !n.visible:
			continue
		n.visible = false
		hidden.append(n)
	for n in get_tree().root.find_children("*", "Sprite3D", true, false):
		if !n.has_method("_enemyMarker") or !n.visible:
			continue
		n.visible = false
		hidden.append(n)
	for c in get_tree().root.find_children("*", "Camera3D", true, false):
		for n in c.get_children():
			if n is Control and n.visible:
				n.visible = false
				hidden.append(n)

func _showHud() -> void:
	for n in hidden:
		if is_instance_valid(n):
			n.visible = true
	hidden.clear()

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
		_showHud()
		get_tree().paused = false
