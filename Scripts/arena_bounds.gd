extends Node3D

@export var player : CharacterBody3D
@export var radius : float = 37.0
@export var ceiling : float = 26.0
@export var floorY : float = -8.0
@export var stiffness : float = 40.0
@export var maxForce : float = 220.0
@export var rectMode : bool = false
@export var halfX : float = 20.0
@export var halfZ : float = 20.0
@export var catchFloor : bool = true

var center : Vector3

func _ready() -> void:
	center = global_position

func _setRect(hx : float, hz : float, roof : float):
	rectMode = true
	catchFloor = false
	halfX = hx
	halfZ = hz
	ceiling = roof
	center = global_position

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var gp = player.global_position
	var v = player.velocity
	var blowing = false

	if rectMode:
		var offX = gp.x - center.x
		var overX = abs(offX) - halfX
		if overX > 0:
			blowing = true
			v.x -= sign(offX) * min(stiffness * overX, maxForce) * delta
		var offZ = gp.z - center.z
		var overZ = abs(offZ) - halfZ
		if overZ > 0:
			blowing = true
			v.z -= sign(offZ) * min(stiffness * overZ, maxForce) * delta
	else:
		var flat = Vector2(gp.x - center.x, gp.z - center.z)
		var dist = flat.length()
		if dist > radius:
			blowing = true
			var over = dist - radius
			var accel = min(stiffness * over, maxForce)
			var inward = -flat.normalized()
			v.x += inward.x * accel * delta
			v.z += inward.y * accel * delta

	var ceilY = center.y + ceiling
	if gp.y > ceilY:
		blowing = true
		v.y -= min(stiffness * (gp.y - ceilY), maxForce) * delta

	if catchFloor:
		var floorW = center.y + floorY
		if gp.y < floorW:
			blowing = true
			v.y += min(stiffness * (floorW - gp.y), maxForce) * delta

	if blowing:
		player.velocity = v
		player.set("knockbackTimer", 0.12)
