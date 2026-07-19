extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var cam = $playerCam

var postions : PackedVector3Array
var rotations : PackedVector3Array
var camPositions : PackedVector3Array
var camRotations : PackedVector3Array
var weapons : PackedInt32Array
var cursor : float = 0.0
var max = 0

@onready var body = $body
var bobTime : float = 0.0
var baseBodyY : float = 0.0

const GUN_TINT = {
	0: Color(0.35, 0.64, 1.0),
	1: Color(1.0, 0.72, 0.30),
	2: Color(0.45, 1.0, 0.85),
}

func _ready() -> void:
	if body.material_override:
		body.material_override = body.material_override.duplicate()
	baseBodyY = body.position.y
	var lvl = Global.currentLevel
	var root = get_parent()
	if "levelIndex" in root:
		lvl = root.levelIndex
	postions = Global.ghostPos.get(lvl, PackedVector3Array())
	rotations = Global.ghostRot.get(lvl, PackedVector3Array())
	camPositions = Global.ghostCamPos.get(lvl, PackedVector3Array())
	camRotations = Global.ghostCamRot.get(lvl, PackedVector3Array())
	weapons = Global.ghostWeapon.get(lvl, PackedInt32Array())
	max = mini(postions.size(), weapons.size())
	if not Global.showGhost:
		visible = false
		set_physics_process(false)
		return
	if max == 0:
		visible = false
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	if cursor >= max - 1:
		visible = false
		set_physics_process(false)
		return
	var i := int(cursor)
	var f := cursor - i
	global_position = postions[i].lerp(postions[i + 1], f)
	global_position.y -= 0.25
	global_rotation = _lerpRot(rotations[i], rotations[i + 1], f)
	cam.global_position = camPositions[i].lerp(camPositions[i + 1], f)
	cam.global_rotation = _lerpRot(camRotations[i], camRotations[i + 1], f)
	if body.material_override:
		body.material_override.set_shader_parameter("body_color", GUN_TINT.get(weapons[i], GUN_TINT[0]))
	cursor += delta * Global.GHOST_HZ

func _process(delta: float) -> void:
	if not visible:
		return
	bobTime += delta
	body.position.y = baseBodyY + sin(bobTime * 2.1) * 0.07
	body.rotation.z = sin(bobTime * 1.4) * 0.05

func _lerpRot(a : Vector3, b : Vector3, f : float) -> Vector3:
	return Vector3(lerp_angle(a.x, b.x, f), lerp_angle(a.y, b.y, f), lerp_angle(a.z, b.z, f))
