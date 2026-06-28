extends Node3D

@export var player : CharacterBody3D
@export var radius : float = 37.0
@export var ceiling : float = 26.0
@export var floorY : float = -8.0
@export var stiffness : float = 40.0
@export var maxForce : float = 220.0

var center : Vector3

func _ready() -> void:
	center = global_position

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var gp = player.global_position
	var v = player.velocity
	var blowing = false

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

	var floorW = center.y + floorY
	if gp.y < floorW:
		blowing = true
		v.y += min(stiffness * (floorW - gp.y), maxForce) * delta

	if blowing:
		player.velocity = v
		player.set("knockbackTimer", 0.12)
