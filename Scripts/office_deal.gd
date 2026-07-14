extends CanvasLayer
signal done

const PURPLE = Color(0.62, 0.25, 1.0)
const TEAL = Color(0.0, 0.85, 0.72)
const TEXT = Color(0.86, 0.86, 0.88)
const DIM = Color(0.55, 0.55, 0.58)
const DANGER = Color(0.9, 0.25, 0.3)
const COST = 20.0

const OPENERS = [
	"relax, blue man. in here, nobody bites. let's talk business.",
	"back already? i do love a repeat customer.",
	"you're wrecking me out there. lucky for you, my rates are fixed.",
	"last call. after this meeting the offer expires. so will you, probably.",
]

var snake
var player
var visitNum := 1
var fade : ColorRect
var panel : PanelContainer
var lineLabel : Label
var office : Node3D
var choosing := true
var savedPlayer : Vector3
var savedPlayerRot : Vector3
var savedCamRot : Vector3
var savedSegs : Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	_run()

func _run() -> void:
	await _fadeTo(1.0, .45)
	_buildOffice()
	_saveSpots()
	_seatEveryone()
	_buildPanel()
	Audio.play("ui_click", .6, -6.0)
	await _fadeTo(0.0, .45)

func _fadeTo(a : float, t : float):
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(fade, "color:a", a, t)
	await tw.finished

func _beat(t : float):
	await get_tree().create_timer(t, true, false, true).timeout

func _box(size : Vector3, pos : Vector3, col : Color):
	var m = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	m.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	m.material_override = mat
	office.add_child(m)
	m.position = pos

func _buildOffice() -> void:
	office = Node3D.new()
	snake.get_parent().add_child(office)
	office.global_position = snake.global_position + Vector3(0, -120, 0)
	var wallCol = Color(.09, .12, .11)
	_box(Vector3(10, .3, 10), Vector3(0, 0, 0), Color(.06, .07, .07))
	_box(Vector3(10, .3, 10), Vector3(0, 4, 0), Color(.05, .06, .06))
	_box(Vector3(.3, 4, 10), Vector3(5, 2, 0), wallCol)
	_box(Vector3(.3, 4, 10), Vector3(-5, 2, 0), wallCol)
	_box(Vector3(10, 4, .3), Vector3(0, 2, 5), wallCol)
	_box(Vector3(10, 4, .3), Vector3(0, 2, -5), wallCol)
	_box(Vector3(2.6, .14, 1.2), Vector3(.6, 1.1, 0), Color(.16, .12, .08))
	_box(Vector3(2.6, 1.0, .12), Vector3(.6, .55, 0), Color(.13, .1, .07))
	_box(Vector3(.9, .5, .6), Vector3(.9, 1.42, .35), Color(.1, .11, .1))
	_box(Vector3(.18, .5, .18), Vector3(1.5, 1.45, -.4), Color(.1, .1, .1))
	var lamp = OmniLight3D.new()
	lamp.light_color = TEAL
	lamp.light_energy = 1.6
	lamp.omni_range = 7
	office.add_child(lamp)
	lamp.position = Vector3(1.5, 1.9, -.4)
	var bulb = OmniLight3D.new()
	bulb.light_color = Color(1, .95, .85)
	bulb.light_energy = .7
	bulb.omni_range = 9
	office.add_child(bulb)
	bulb.position = Vector3(0, 3.5, 0)
	var sign = Label3D.new()
	sign.text = "SNEK & CO.\nVENOM MANAGEMENT"
	sign.font_size = 90
	sign.modulate = TEAL
	sign.pixel_size = .004
	sign.rotation.y = -PI / 2
	office.add_child(sign)
	sign.position = Vector3(4.7, 2.6, 0)
	var poster = Label3D.new()
	poster.text = "employee of the eon:\nthe snake"
	poster.font_size = 48
	poster.modulate = DIM
	poster.pixel_size = .003
	poster.rotation.y = PI
	office.add_child(poster)
	poster.position = Vector3(-1.5, 2.2, 4.7)

func _saveSpots() -> void:
	savedPlayer = player.global_position
	savedPlayerRot = player.rotation
	savedCamRot = player.playerCam.rotation
	savedSegs.clear()
	for seg in snake.segms:
		savedSegs.append([seg.global_position, seg.rotation])

func _seatEveryone() -> void:
	var base = office.global_position
	var head = snake.segms[0]
	head.global_position = base + Vector3(1.7, 2.1, 0)
	head.rotation = Vector3(0, 0, .1)
	for i in range(1, snake.segms.size()):
		var ang = 1.0 + i * .9
		snake.segms[i].global_position = base + Vector3(2.8 + cos(ang) * .8, .55, sin(ang) * 1.3)
		snake.segms[i].rotation = Vector3(0, ang, 0)
	snake.glasses.visible = true
	player.global_position = base + Vector3(-2.1, 1.5, 0)
	player.rotation = Vector3(0, -PI / 2, 0)
	player.velocity = Vector3.ZERO
	player.playerCam.rotation = Vector3(-.04, 0, 0)

func _buildPanel() -> void:
	panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(.04, .04, .05, .97)
	style.border_color = PURPLE
	style.set_border_width_all(2)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 240
	panel.offset_right = -240
	panel.offset_top = -230
	panel.offset_bottom = -36
	add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var speaker = Label.new()
	speaker.text = "THE SNAKE, ESQ."
	speaker.add_theme_font_size_override("font_size", 15)
	speaker.add_theme_color_override("font_color", PURPLE)
	box.add_child(speaker)

	lineLabel = Label.new()
	lineLabel.text = OPENERS[clamp(visitNum - 1, 0, OPENERS.size() - 1)]
	lineLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lineLabel.add_theme_font_size_override("font_size", 19)
	lineLabel.add_theme_color_override("font_color", TEXT)
	box.add_child(lineLabel)

	var status = Label.new()
	status.text = "the deal: one paralysis level off, for %d health.        you: paralysis %d, health %d" % [int(COST), player.paraLevel, int(player.health)]
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", DIM)
	box.add_child(status)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)

	var acceptBtn = Button.new()
	acceptBtn.text = "TAKE THE DEAL"
	acceptBtn.custom_minimum_size = Vector2(260, 44)
	acceptBtn.add_theme_font_size_override("font_size", 17)
	if player.health <= COST:
		acceptBtn.text = "TAKE THE DEAL  [THIS WILL KILL YOU]"
		acceptBtn.add_theme_color_override("font_color", DANGER)
		acceptBtn.add_theme_color_override("font_hover_color", DANGER)
	acceptBtn.pressed.connect(_accept)
	row.add_child(acceptBtn)

	var declineBtn = Button.new()
	declineBtn.text = "NO DEAL"
	declineBtn.custom_minimum_size = Vector2(180, 44)
	declineBtn.add_theme_font_size_override("font_size", 17)
	declineBtn.pressed.connect(_decline)
	row.add_child(declineBtn)

func _accept() -> void:
	if !choosing:
		return
	choosing = false
	player.paraLevel = max(player.paraLevel - 1, 0)
	Audio.play("pickup", 1.1, -2.0)
	player._takeDamage(COST)
	if player.health > 0:
		lineLabel.text = "pleasure doing business."
	else:
		lineLabel.text = "...oh. you really should read the fine print."
	await _beat(.9)
	_leave(player.health <= 0)

func _decline() -> void:
	if !choosing:
		return
	choosing = false
	lineLabel.text = "suit yourself. the venom stays."
	await _beat(.8)
	_leave(false)

func _leave(died : bool) -> void:
	panel.visible = false
	await _fadeTo(1.0, .4)
	for i in range(snake.segms.size()):
		snake.segms[i].global_position = savedSegs[i][0]
		snake.segms[i].rotation = savedSegs[i][1]
	snake.glasses.visible = false
	player.global_position = savedPlayer
	player.rotation = savedPlayerRot
	player.playerCam.rotation = savedCamRot
	player.velocity = Vector3.ZERO
	office.queue_free()
	get_tree().paused = false
	if !died:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _fadeTo(0.0, .35)
	done.emit()
	queue_free()

func _input(event : InputEvent) -> void:
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
