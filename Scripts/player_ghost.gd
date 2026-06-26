extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var cam = $playerCam

var postions = []
var rotations = []
var camPositions = []
var camRotations = []
var weapons = []
var i :int = 0
var max = 0

@onready var gun = $playerCam/gun
@onready var shotGun = $playerCam/shotGun

func _ready() -> void:
	var lvl = Global.currentLevel
	var root = get_parent()
	if "levelIndex" in root:
		lvl = root.levelIndex
	postions = Global.ghostPos.get(lvl, [])
	rotations = Global.ghostRot.get(lvl, [])
	camPositions = Global.ghostCamPos.get(lvl, [])
	camRotations = Global.ghostCamRot.get(lvl, [])
	weapons = Global.ghostWeapon.get(lvl, [])
	max = postions.size()

func _physics_process(delta: float) -> void:
	if i < max:
		global_position = postions[i]
		global_position.y -= 0.25
		global_rotation = rotations[i]
		cam.global_position = camPositions[i]
		cam.global_rotation = camRotations[i]
		if weapons[i] == 0:
			gun.visible = true
			shotGun.visible = false
		elif weapons[i] == 1:
			gun.visible = false
			shotGun.visible = true
		i+=1
	else:
		visible =false
