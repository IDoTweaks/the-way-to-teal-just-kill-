extends CharacterBody3D
func _lobber(): pass
func _enemy(): pass

const SPEED = 2.0
@export var scoreWorth = 4000
@export var health = 50
@onready var body = $body
@onready var barrel = $body/barrel
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var navAgent : NavigationAgent3D
@export var accelaration = 8
@export var globDamage = 18
@export var fireGap : float = 2.5
@export var flightTime : float = 1.3
@export var sightDist : float = 40.0
@export var retreatDist : float = 8.0
@export var player : CharacterBody3D
@onready var globScene = preload("res://ObjectScenes/kettleGlob.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var muzzleParticles = preload("res://Particles/enemyMuzzle.tscn")
var particleInstance
var maxHealth : float = 50.0
var target
var mode : String = "idle"
var gotShot = false
var shouldMove = false
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var baseBodyY : float = 0.0
var fireCd : float = 1.0
var lean : float = 0.0
var winding = false
var buffMult : float = 1.0

func _buff(on):
	buffMult = 1.4 if on else 1.0

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "chase"

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	body._updateMat(1)
	baseBodyY = body.position.y
	await get_tree().physics_frame

func _activeTarget():
	if target != null and is_instance_valid(target):
		return target
	return player

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	health -= dmg
	Audio.play("enemy_hit", 1.0, -4.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		body._hitPunch()
		body._updateMat(health / maxHealth)
	else:
		_die()

func _die():
	if dead:
		return
	dead = true
	body._updateMat(0)
	Audio.play("enemy_death")
	var tgt = _activeTarget()
	if tgt and tgt.has_method("_onKill"):
		tgt._onKill()
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	var dud = globScene.instantiate()
	dud.damage = 0
	dud.poolScale = .4
	dud.poolLife = 1.5
	get_parent().add_child(dud)
	dud.global_position = barrel.global_position
	dud.velocity = global_transform.basis.z * 1.5 + Vector3(0, 2.0, 0)
	_deathAnim()

func _deathAnim():
	set_physics_process(false)
	velocity = Vector3.ZERO
	body._killTweens()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .22)
	tw.tween_property(body, "rotation:z", body.rotation.z + PI * .7, .22)
	await tw.finished
	queue_free()

func _floorPoint(from : Vector3):
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from + Vector3(0, 3, 0), from + Vector3(0, -8, 0))
	var ex : Array[RID] = [self.get_rid()]
	var tgt = _activeTarget()
	if tgt != null:
		ex.append(tgt.get_rid())
	ray.exclude = ex
	var hit = space.intersect_ray(ray)
	if hit:
		return hit.position + Vector3(0, .05, 0)
	return null

func _spawnTargetRing(at : Vector3, life : float):
	var ring = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius = 1.15
	mesh.outer_radius = 1.45
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, .55, .08)
	mat.emission_enabled = true
	mat.emission = Color(1, .55, .08)
	mat.emission_energy_multiplier = 2.0
	ring.mesh = mesh
	ring.material_override = mat
	get_parent().add_child(ring)
	ring.global_position = at
	ring.scale = Vector3(.15, 1, .15)
	var tw = ring.create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "scale", Vector3.ONE, .25)
	var pulse = ring.create_tween()
	pulse.set_loops()
	pulse.tween_property(mat, "emission_energy_multiplier", 6.0, .18)
	pulse.tween_property(mat, "emission_energy_multiplier", 2.0, .18)
	get_tree().create_timer(life).timeout.connect(func():
		if is_instance_valid(ring):
			ring.queue_free())

func _fire():
	var tgt = _activeTarget()
	if tgt == null:
		return
	winding = true
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "lean", -.5, .4 / buffMult)
	await tw.finished
	if dead or !is_instance_valid(self):
		return
	tgt = _activeTarget()
	if tgt == null:
		winding = false
		return
	var to = tgt.global_position
	var pnt = _floorPoint(to)
	if pnt != null:
		_spawnTargetRing(pnt, flightTime)
		to = pnt
	var g = globScene.instantiate()
	get_parent().add_child(g)
	g.global_position = barrel.global_position
	g.damage = globDamage
	g.lifeTime = flightTime + 2.0
	g.velocity = _lobVelocity(barrel.global_position, to, flightTime)
	add_collision_exception_with(g)
	g.add_collision_exception_with(self)
	Audio.play("shotgun", 1.4, -10.0)
	var muzzle = muzzleParticles.instantiate()
	get_parent().add_child(muzzle)
	muzzle.global_position = barrel.global_position
	muzzle.emitting = true
	var tw2 = create_tween()
	tw2.set_trans(Tween.TRANS_BACK)
	tw2.set_ease(Tween.EASE_OUT)
	tw2.tween_property(self, "lean", .18, .1)
	tw2.tween_property(self, "lean", 0.0, .35)
	winding = false
	fireCd = fireGap / buffMult

func _lobVelocity(from : Vector3, to : Vector3, t : float) -> Vector3:
	var g = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var d = to - from
	var v = Vector3.ZERO
	v.x = d.x / t
	v.z = d.z / t
	v.y = (d.y + .5 * g * t * t) / t
	return v

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var tgt = _activeTarget()
	if tgt != null and is_instance_valid(tgt):
		var dist = global_position.distance_to(tgt.global_position)
		if dist < retreatDist:
			var away = global_position - tgt.global_position
			away.y = 0
			away = away.normalized()
			velocity.x = away.x * SPEED
			velocity.z = away.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, 10 * delta)
			velocity.z = move_toward(velocity.z, 0, 10 * delta)
		if dist <= sightDist and !winding:
			fireCd -= delta
			if fireCd <= 0:
				_fire()

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
	animTime += delta
	body.rotation.x = lean
	body.position.y = baseBodyY + sin(animTime * 1.8) * 0.06
	var tgt = _activeTarget()
	if tgt != null and is_instance_valid(tgt):
		var look = tgt.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 5.0)
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
	txt.lookat = _activeTarget()

func _on_chase_body_entered(bod: Node3D) -> void:
	if bod.has_method("player"):
		target = bod
		mode = "chase"

func _on_chase_body_exited(bod: Node3D) -> void:
	pass
