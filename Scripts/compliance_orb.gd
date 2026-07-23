extends CharacterBody3D

func _complianceOrb():pass

@export var speed : float = 7.0
@export var damage : int = 20
@export var knockback : float = 12.0
@export var lifeTime : float = 7.0
@export var reverseAt : float = 6.0
@export var returnMult : float = 1.9
@export var returnTurn : float = 2.6
@export var hitRadius : float = 1.6
@export var orbDamage : float = 1.0

const OPEN_COL = Color(0, .85, .78)
const SHUT_COL = Color(1, .38, 0)

var dir = Vector3.FORWARD
var charge : float = 0.0
var reversed = false
var owner_boss
var thrower
var spun : float = 0.0
var trailCd : float = 0.0
var mat : StandardMaterial3D

@onready var mesh = $MeshInstance3D
@onready var impactParticles = preload("res://Particles/enemyBulletImpact.tscn")
@onready var burstParticles = preload("res://Particles/pickupBurst.tscn")
@onready var trailParticles = preload("res://Particles/dashTrail.tscn")

func _ready() -> void:
	if mesh.material_override:
		mesh.material_override = mesh.material_override.duplicate()
		mat = mesh.material_override

func _makeTarg(targ):
	thrower = targ

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	if reversed:
		return
	charge += (reverseAt if dmg >= 100.0 else 1.0)
	_pulse()
	if charge >= reverseAt:
		_reverse()

func _pulse():
	Audio.play("enemy_hit", 1.0 + clamp(charge / reverseAt, 0.0, 1.0) * .9, -10.0)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(mesh, "scale", Vector3.ONE * 1.35, .07)
	tw.tween_property(mesh, "scale", Vector3.ONE, .12)
	if mat != null:
		mat.emission_energy_multiplier = 2.0 + clamp(charge / reverseAt, 0.0, 1.0) * 8.0

func _reverse():
	reversed = true
	dir = -dir
	speed *= returnMult
	if mat != null:
		mat.albedo_color = OPEN_COL
		mat.emission = OPEN_COL
		mat.emission_energy_multiplier = 9.0
	if owner_boss != null and is_instance_valid(owner_boss):
		remove_collision_exception_with(owner_boss)
		if owner_boss is CollisionObject3D:
			owner_boss.remove_collision_exception_with(self)
		if owner_boss.has_method("_orbTurned"):
			owner_boss._orbTurned(self)
	Audio.play("walljump", .9, -3.0)
	var p = burstParticles.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true

func _process(delta: float) -> void:
	lifeTime -= delta
	if lifeTime <= 0:
		_splat()
		return
	spun += delta
	mesh.rotation.y = spun * 3.0
	trailCd -= delta
	if trailCd <= 0.0:
		trailCd = .06
		var t = trailParticles.instantiate()
		get_parent().add_child(t)
		t.global_position = global_position
		t.emitting = true

func _physics_process(delta: float) -> void:
	if reversed and owner_boss != null and is_instance_valid(owner_boss):
		var aim = owner_boss.global_position + Vector3(0, .4, 0)
		var want = global_position.direction_to(aim)
		dir = dir.slerp(want, clamp(returnTurn * delta, 0.0, 1.0)).normalized()
		if global_position.distance_to(aim) <= hitRadius:
			if owner_boss.has_method("_orbReturned"):
				owner_boss._orbReturned(orbDamage)
			_splat()
			return
	velocity = dir * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		var body = collision.get_collider()
		if body.has_method("player"):
			if reversed:
				add_collision_exception_with(body)
			else:
				_hitPlayer(body)
		elif body.has_method("_compliance"):
			if reversed:
				body._orbReturned(orbDamage)
				_splat()
			else:
				add_collision_exception_with(body)
		elif body.has_method("_enemy"):
			add_collision_exception_with(body)
		else:
			_splat()

func _hitPlayer(body):
	if body.has_method("_takeDamage"):
		body._takeDamage(damage, global_position - dir * 5.0)
	if body.has_method("_applyForce"):
		body._applyForce(global_position - dir * 2.0, knockback, 12.0)
	_splat()

func _splat():
	var p = impactParticles.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	Audio.play("slam", 1.6, -16.0)
	queue_free()
