extends CharacterBody3D
func _glob():pass

@export var damage : int = 10
@export var lifeTime : float = 6.0
@export var poolLife : float = 4.0
@export var poolScale : float = .75

var spun : float = 0.0
var trailCd : float = 0.0
@onready var mesh = $MeshInstance3D
@onready var acidScene = preload("res://ObjectScenes/kettleAcid.tscn")
@onready var impactParticles = preload("res://Particles/enemyBulletImpact.tscn")
@onready var trailParticles = preload("res://Particles/dashTrail.tscn")

func _process(delta: float) -> void:
	lifeTime -= delta
	if lifeTime <= 0:
		_splat()
		return
	spun += delta
	mesh.rotation.x = spun * 7.0
	mesh.rotation.z = spun * 5.0
	var wob = 1.0 + sin(spun * 18.0) * .12
	mesh.scale = Vector3(wob, 2.0 - wob, wob)
	trailCd -= delta
	if trailCd <= 0.0:
		trailCd = .05
		var t = trailParticles.instantiate()
		get_parent().add_child(t)
		t.global_position = global_position
		t.emitting = true

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	var col = move_and_collide(velocity * delta)
	if col:
		var b = col.get_collider()
		if b.has_method("_enemy") or b.has_method("_glob"):
			add_collision_exception_with(b)
			return
		if b.has_method("player") and b.has_method("_takeDamage"):
			b._takeDamage(damage, global_position)
		_splat()

func _splat():
	var p = impactParticles.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	Audio.play("slam", 1.5, -14.0)
	var pnt = _floorPoint(global_position)
	if pnt != null:
		var a = acidScene.instantiate()
		get_parent().add_child(a)
		a.global_position = pnt
		a.lifeTime = poolLife
		a.scale = Vector3(poolScale, 1.0, poolScale)
	queue_free()

func _floorPoint(from : Vector3):
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from + Vector3(0, 1.5, 0), from + Vector3(0, -5, 0))
	ray.exclude = [self.get_rid()]
	var hit = space.intersect_ray(ray)
	if hit:
		return hit.position + Vector3(0, .04, 0)
	return null
