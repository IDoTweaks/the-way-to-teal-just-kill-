extends CharacterBody3D
func _printer(): pass
func _enemy(): pass

@export var scoreWorth = 6000
@export var health = 120
@onready var body = $body
@onready var tray = $body/tray
@onready var light = $body/light
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var printGap : float = 2.5
@export var copyCap : int = 4
@export var jamEvery : int = 3
@export var jamTime : float = 2.0
@export var player : CharacterBody3D
@onready var copyScene = preload("res://ObjectScenes/gnat.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var dustParticles = preload("res://Particles/landDust.tscn")
var particleInstance
var maxHealth : float = 120.0
var target
var mode : String = "idle"
var gotShot = false
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var printCd : float = 1.5
var printCount : int = 0
var jammed = false
var jamTimer : float = 0.0
var shake : float = 0.0
var copies : Array = []
var lightMat : StandardMaterial3D
var buffMult : float = 1.0

func _buff(on):
	buffMult = 1.4 if on else 1.0

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "print"

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	body._updateMat(1)
	if light.material_override:
		light.material_override = light.material_override.duplicate()
		lightMat = light.material_override
	await get_tree().physics_frame

func _activeTarget():
	if target != null and is_instance_valid(target):
		return target
	return player

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	if jammed:
		dmg *= 2
	health -= dmg
	Audio.play("enemy_hit", .9, -4.0)
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
	Audio.play("enemy_death", .8, -2.0)
	var tgt = _activeTarget()
	if tgt and tgt.has_method("_onKill"):
		tgt._onKill()
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	_paperFan()
	_deathAnim()

func _paperFan():
	for i in 7:
		var paper = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(.32, .015, .42)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(.96, .96, .92)
		paper.mesh = mesh
		paper.material_override = mat
		get_parent().add_child(paper)
		paper.global_position = global_position + Vector3(0, 1.4, 0)
		var ang = randf() * TAU
		var out = Vector3(cos(ang), 0, sin(ang)) * randf_range(1.2, 3.0)
		var tw = paper.create_tween()
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_QUAD)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(paper, "position", paper.position + out + Vector3(0, randf_range(1.0, 2.2), 0), .45)
		tw.tween_property(paper, "rotation", Vector3(randf() * TAU, randf() * TAU, randf() * TAU), .9)
		tw.chain().set_ease(Tween.EASE_IN)
		tw.chain().tween_property(paper, "position:y", .05, randf_range(.5, .9))
		tw.chain().tween_interval(1.4)
		tw.chain().tween_property(paper, "scale", Vector3.ZERO, .3)
		tw.finished.connect(paper.queue_free)

func _deathAnim():
	set_physics_process(false)
	body._killTweens()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .25)
	tw.tween_property(body, "rotation:z", body.rotation.z + PI * .5, .25)
	await tw.finished
	queue_free()

func _pruneCopies():
	copies = copies.filter(func(c): return is_instance_valid(c) and !c.dead)

func _printCopy():
	_pruneCopies()
	if copies.size() >= copyCap:
		return
	shake = 1.0
	Audio.play("ui_click", .6, -8.0)
	Audio.play("ui_click", 1.4, -12.0)
	var c = copyScene.instantiate()
	c.scoreWorth = 0
	get_parent().add_child(c)
	c.global_position = tray.global_position + Vector3(0, .1, 0)
	var out = -global_transform.basis.z
	c.velocity = out * 4.0 + Vector3(0, 2.5, 0)
	add_collision_exception_with(c)
	c.add_collision_exception_with(self)
	var tgt = _activeTarget()
	if tgt != null and c.has_method("_makeTarg"):
		c._makeTarg(tgt)
	copies.append(c)
	var d = dustParticles.instantiate()
	get_parent().add_child(d)
	d.global_position = tray.global_position
	d.emitting = true
	printCount += 1
	if printCount % jamEvery == 0:
		_jam()

func _jam():
	jammed = true
	jamTimer = jamTime
	Audio.play("ui_click", .45, -4.0)
	Audio.play("enemy_hit", .4, -8.0)
	Audio.play("lose", 1.8, -18.0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if jammed:
		jamTimer -= delta
		if jamTimer <= 0:
			jammed = false
			Audio.play("pickup", 1.3, -12.0)
	elif mode == "print":
		printCd -= delta * buffMult
		if printCd <= 0:
			printCd = printGap
			_printCopy()
	move_and_slide()

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	shake = move_toward(shake, 0.0, delta * 3.0)
	var j = 1.0 if jammed else shake
	body.position.x = randf_range(-.05, .05) * j
	body.position.z = randf_range(-.05, .05) * j
	body.rotation.z = sin(animTime * 40.0) * .04 * j
	if lightMat != null:
		if jammed:
			lightMat.albedo_color = Color(1, .15, .1)
			lightMat.emission = Color(1, .15, .1)
			lightMat.emission_energy_multiplier = 3.0 + abs(sin(animTime * 16.0)) * 5.0
		else:
			lightMat.albedo_color = Color(0, 1, .4)
			lightMat.emission = Color(0, 1, .4)
			lightMat.emission_energy_multiplier = 1.5 + shake * 4.0
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
		mode = "print"

func _on_chase_body_exited(bod: Node3D) -> void:
	pass
