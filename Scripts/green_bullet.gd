extends CharacterBody3D

@export var speed : float = 5.0
@export var damage : int = 20.0
@export var dest : Vector3
@export var lifeTime : float = 10.0
var dir
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dir = global_position.direction_to(dest)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	lifeTime -= delta
	if lifeTime <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	velocity.z = dir.z * speed
	velocity.y = dir.y * speed
	velocity.x = dir.x * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		_bounce(collision)

func _bounce(collision : KinematicCollision3D):
	dir = dir.bouce(collision.get_normal())

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("_takeDamage"):
		body._takeDamage(damage)
