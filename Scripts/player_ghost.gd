extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var cam = $playerCam

var postions = Global.positionSave
var rotations = Global.rotationSave
var camPositions = Global.camPositionSave
var camRotations = Global.camRotationSave
var weapons = Global.weaponSave
var i :int = 0
var max = 0

@onready var gun = $playerCam/gun
@onready var shotGun = $playerCam/shotGun

func _ready() -> void:
	max = postions.size()

func _physics_process(delta: float) -> void:
	if i < max:
		global_position = postions[i]
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
		print("moved")
	else:
		visible =false
