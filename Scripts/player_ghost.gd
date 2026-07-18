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

@onready var gun = $playerCam/gun
@onready var shotGun = $playerCam/shotGun

func _ready() -> void:
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
	if weapons[i] == 0:
		gun.visible = true
		shotGun.visible = false
	elif weapons[i] == 1:
		gun.visible = false
		shotGun.visible = true
	elif weapons[i] == 2:
		gun.visible = false
		shotGun.visible = false
	cursor += delta * Global.GHOST_HZ

func _lerpRot(a : Vector3, b : Vector3, f : float) -> Vector3:
	return Vector3(lerp_angle(a.x, b.x, f), lerp_angle(a.y, b.y, f), lerp_angle(a.z, b.z, f))
