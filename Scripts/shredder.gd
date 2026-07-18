extends CharacterBody3D
func _shredder(): pass
func _enemy(): pass

const SPEED = 2.5
@export var scoreWorth = 7000
@export var health = 220
@onready var body = $body
@onready var intakeSpot = $body/intakeSpot
@onready var toothL = $body/toothL
@onready var toothR = $body/toothR
@onready var port = $port
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var navAgent : NavigationAgent3D
@export var accelaration = 6
@export var grindDamage = 8
@export var grindTick : float = .3
@export var pullRange : float = 7.0
@export var pullAccel : float = 6.0
@export var turnRate : float = 1.8
@export var player : CharacterBody3D
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var trailParticles = preload("res://Particles/dashTrail.tscn")
var particleInstance
var maxHealth : float = 220.0
var target
var mode : String = "idle"
var gotShot = false
var shouldMove = false
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var baseBodyY : float = 0.0
var grindCd : float = 0.0
var suckCd : float = 0.0
var playerInside = false
var pulling = false
var buffMult : float = 1.0

const CONFETTI_COLS = [Color(0, 1, .8), Color(1, .55, .08), Color(.96, .96, .92), Color(0, 1, .27)]

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
	add_collision_exception_with(port)
	await get_tree().physics_frame

func _targetValid():
	if target != null and is_instance_valid(target):
		return true
	if player != null and is_instance_valid(player):
		target = player
		return true
	return false

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	if dead:
		return
	health -= dmg
	Audio.play("enemy_hit", .8, -4.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		body._hitPunch()
		body._updateMat(health / maxHealth)
	else:
		_die()

func _portDamage(dmg):
	if dead:
		return
	Audio.play("enemy_hit", 1.5, -8.0)
	_damage(dmg)

func _confetti(at : Vector3, count : int):
	for i in count:
		var bit = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(.09, .01, .14)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = CONFETTI_COLS[randi() % CONFETTI_COLS.size()]
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		bit.mesh = mesh
		bit.material_override = mat
		get_parent().add_child(bit)
		bit.global_position = at
		var ang = randf() * TAU
		var out = Vector3(cos(ang), 0, sin(ang)) * randf_range(.6, 2.2)
		var tw = bit.create_tween()
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_QUAD)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(bit, "position", bit.position + out + Vector3(0, randf_range(.8, 2.0), 0), .4)
		tw.tween_property(bit, "rotation", Vector3(randf() * TAU, randf() * TAU, randf() * TAU), .7)
		tw.chain().set_ease(Tween.EASE_IN)
		tw.chain().tween_property(bit, "position:y", .04, randf_range(.4, .7))
		tw.chain().tween_interval(.8)
		tw.chain().tween_property(bit, "scale", Vector3.ZERO, .25)
		tw.finished.connect(bit.queue_free)

func _die():
	if dead:
		return
	dead = true
	body._updateMat(0)
	Audio.play("enemy_death", .7, -1.0)
	if target and target.has_method("_onKill"):
		target._onKill()
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	_confetti(global_position + Vector3(0, 1, 0), 22)
	_deathAnim()

func _deathAnim():
	set_physics_process(false)
	velocity = Vector3.ZERO
	body._killTweens()
	port.queue_free()
	Audio.play("ui_click", .4, -4.0)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3(.05, 1.1, 1.0), .5)
	tw.tween_property(body, "scale", Vector3.ZERO, .12)
	await tw.finished
	Audio.play("slam", 1.3, -6.0)
	queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	pulling = false
	if mode == "chase" and _targetValid():
		var look = target.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * turnRate)
		var facing = -global_transform.basis.z
		facing.y = 0
		facing = facing.normalized()
		if look.length() > 1.4:
			velocity.x = facing.x * SPEED * buffMult
			velocity.z = facing.z * SPEED * buffMult
		else:
			velocity.x = 0
			velocity.z = 0
		var toP = target.global_position - intakeSpot.global_position
		if toP.length() < pullRange and abs(toP.y) < 3.5 and facing.dot(Vector3(toP.x, 0, toP.z).normalized()) > .45:
			pulling = true
			target.velocity += -toP.normalized() * pullAccel * delta * (toP.length() / pullRange + .4)
			suckCd -= delta
			if suckCd <= 0:
				suckCd = .12
				var t = trailParticles.instantiate()
				get_parent().add_child(t)
				t.global_position = intakeSpot.global_position + toP.normalized() * randf_range(1.0, pullRange * .8) + Vector3(randf_range(-.6, .6), randf_range(0, 1.2), randf_range(-.6, .6))
				t.emitting = true

	if playerInside and _targetValid():
		grindCd -= delta
		if grindCd <= 0:
			grindCd = grindTick
			target._takeDamage(grindDamage, intakeSpot.global_position)
			_confetti(intakeSpot.global_position + Vector3(0, .8, 0), 4)
			Audio.play("slam", 1.8, -10.0)

	var horizontal = Vector3(velocity.x, 0, velocity.z).normalized()
	if horizontal.length() > 0.1:
		var space = get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.create(global_position + horizontal * 1.2, global_position + horizontal * 1.2 + Vector3(0, -2, 0))
		ray.exclude = [self.get_rid(), port.get_rid()]
		if not space.intersect_ray(ray):
			velocity.x = 0
			velocity.z = 0

	move_and_slide()

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	var vib = .02 + (0.03 if pulling else 0.0)
	body.position.x = randf_range(-vib, vib)
	body.position.z = randf_range(-vib, vib)
	body.position.y = baseBodyY + randf_range(-.01, .01)
	var spin = delta * (14.0 if pulling or playerInside else 6.0)
	toothL.rotation.x += spin
	toothR.rotation.x -= spin
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

func _on_intake_body_entered(bod: Node3D) -> void:
	if bod.has_method("player"):
		playerInside = true

func _on_intake_body_exited(bod: Node3D) -> void:
	if bod.has_method("player"):
		playerInside = false
