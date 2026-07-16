extends Node3D

@export var growRate = 5.0
@export var maxSize = 5.0
var damage = 0 :
	set(value):
		damage = value
		if text != null:
			text.text = str(value)
@onready var text = $Label3D
var orgScale
var lookat
func _ready() -> void:
	orgScale = text.scale
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.text = str(damage)
func _process(delta: float) -> void:
	_grow(delta)
func _resetScale():
	text.scale = orgScale
func _grow(delta):
	if text.scale.x < maxSize:
		text.scale.x += growRate * delta
		text.scale.y += growRate * delta
	else:
		queue_free()
