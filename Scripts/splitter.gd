extends CharacterBody3D
func _splitter(): pass
func _enemy(): pass

const TIER_HP = [8, 25, 80]
const TIER_SPEED = [7.5, 5.5, 4.0]
const TIER_DMG = [3, 5, 8]
const TIER_SCALE = [.38, .6, 1.0]

@export var tier : int = 2
@export var scoreWorth = 4000
@export var health = 80
@onready var body = $body
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var navAgent : NavigationAgent3D
@export var accelaration = 8
@export var damage = 8
@export var biteRange : float = 1.9
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance
var SPEED = 4.0
var maxHealth : float = 80.0
var target
var mode : String = "idle"
var gotShot = false
var shouldMove = false
var canAttack : bool = true
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var baseBodyY : float = 0.0
var baseBodyScale : Vector3 = Vector3.ONE
var punch : float = 0.0
var buffMult : float = 1.0

func _buff(on):
	buffMult = 1.4 if on else 1.0

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "chase"

func _ready() -> void:
	add_to_group("enemies")
	tier = clamp(tier, 0, 2)
	health = TIER_HP[tier]
	SPEED = TIER_SPEED[tier]
	damage = TIER_DMG[tier]
	maxHealth = health
	var f = TIER_SCALE[tier]
	if f < 1.0:
		body.scale *= f
		body.position.y = .8 * f
		var col = $CollisionShape3D
		col.shape = col.shape.duplicate()
		col.shape.radius = .8 * f
		col.position.y = .8 * f
		$EnemyMarker.position.y = 1.9 * f + .4
		biteRange = 1.9 * f + .4
	body._updateMat(1)
	baseBodyY = body.position.y
	baseBodyScale = body.scale
	await get_tree().physics_frame

func _targetValid():
	return target != null and is_instance_valid(target)

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	health -= dmg
	Audio.play("enemy_hit", 1.0 + (2 - tier) * .25, -4.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		punch = 1.0
		body._updateMat(health / maxHealth)
	else:
		_die()

func _die():
	if dead:
		return
	dead = true
	body._updateMat(0)
	Audio.play("enemy_death", 1.0 + (2 - tier) * .3, -3.0)
	if target and target.has_method("_onKill"):
		target._onKill()
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	if tier > 0:
		_split()
	else:
		_deathAnim()

func _split():
	set_physics_process(false)
	velocity = Vector3.ZERO
	body._killTweens()
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(body, "scale", baseBodyScale * 1.3, .1)
	await tw.finished
	if !is_instance_valid(self):
		return
	var scene = load("res://ObjectScenes/splitter.tscn")
	var kids = []
	var baseAng = randf() * TAU
	for i in 2:
		var kid = scene.instantiate()
		kid.tier = tier - 1
		kid.scoreWorth = 0
		get_parent().add_child(kid)
		var ang = baseAng + PI * i
		var out = Vector3(cos(ang), 0, sin(ang))
		kid.global_position = global_position + out * .5 + Vector3(0, .3, 0)
		kid.velocity = out * 5.0 + Vector3(0, 4.0, 0)
		if _targetValid():
			kid._makeTarg(target)
		kids.append(kid)
	for a in kids:
		for b in kids:
			if a != b:
				a.add_collision_exception_with(b)
	Audio.play("slam", 1.7, -12.0)
	queue_free()

func _deathAnim():
	set_physics_process(false)
	velocity = Vector3.ZERO
	body._killTweens()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .2)
	tw.tween_property(body, "rotation:z", body.rotation.z + PI * .7, .2)
	await tw.finished
	queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if mode == "chase" and _targetValid():
		var hd = target.global_position - global_position
		hd.y = 0
		hd = hd.normalized()
		velocity.x = hd.x * SPEED * buffMult
		velocity.z = hd.z * SPEED * buffMult

	if _targetValid() and canAttack and global_position.distance_to(target.global_position) < biteRange:
		canAttack = false
		target._takeDamage(damage, global_position)
		get_tree().create_timer(1.0 / buffMult).timeout.connect(func(): canAttack = true)

	var horizontal = Vector3(velocity.x, 0, velocity.z).normalized()
	if horizontal.length() > 0.1:
		var space = get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.create(global_position + horizontal * .6, global_position + horizontal * .6 + Vector3(0, -2, 0))
		ray.exclude = [self.get_rid()]
		if not space.intersect_ray(ray):
			velocity.x = 0
			velocity.z = 0

	move_and_slide()

func _process(delta: float) -> void:
	if dead:
		return
	var spd = Vector3(velocity.x, 0, velocity.z).length()
	animTime += delta * (1.0 + spd * .3)
	punch = move_toward(punch, 0.0, delta * 6.0)
	var wob = sin(animTime * 5.0) * .08
	body.scale = Vector3(baseBodyScale.x * (1.0 + wob), baseBodyScale.y * (1.0 - wob), baseBodyScale.z * (1.0 + wob)) * (1.0 + punch * .16)
	body.position.y = baseBodyY + abs(sin(animTime * 5.0)) * .06
	if _targetValid():
		var look = target.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 7.0)
	if txt == null:
		textActive = false

func _updateDmgTxt(moreDamage:int):
	if txt != null:
		txt.damage += moreDamage
		txt.global_position = textSpawn.global_position
		txt._resetScale()

func _spawnDmgTxt(damage:int):
	txt = dmgTxt.instantiate()
	get_parent().add_child(txt)
	txt.damage = damage
	txt.global_position = textSpawn.global_position
	textActive = true
	txt.lookat = target

func _on_chase_body_entered(bod: Node3D) -> void:
	if bod.has_method("player"):
		target = bod
		mode = "chase"

func _on_chase_body_exited(bod: Node3D) -> void:
	pass
