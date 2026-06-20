extends Node3D

@export var growRate = 2.5
@export var maxSize = 5.0
var damage = 0
@onready var text = $Label3D
@onready var orgScale
@onready var lookat

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	orgScale = text.scale


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_grow(delta)

func _resetScale():
	text.scale = orgScale

func _grow(delta):
	if text.scale.x < maxSize:
		look_at(lookat.global_position,Vector3.UP)
		rotate_object_local(Vector3.UP, PI)
		text.text = str(damage)
		text.scale.x += growRate * delta
		text.scale.y += growRate * delta
	else:
		queue_free()
