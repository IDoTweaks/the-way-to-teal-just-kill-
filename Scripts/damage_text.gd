extends Node3D

@export var growRate = 5.0
@export var maxSize = 5.0
@export var floatSpeed = 1.6
@export var fadeTime = 0.4
var damage = 0 :
	set(value):
		damage = value
		if text != null:
			text.text = str(value)
@onready var text = $Label3D
var orgScale
var lookat
var fadeAccum = 0.0
func _ready() -> void:
	orgScale = text.scale
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.text = str(damage)
func _process(delta: float) -> void:
	global_position.y += floatSpeed * delta
	_grow(delta)
func _resetScale():
	text.scale = orgScale
	text.modulate.a = 1.0
	fadeAccum = 0.0
func _grow(delta):
	if text.scale.x < maxSize:
		text.scale.x += growRate * delta
		text.scale.y += growRate * delta
	else:
		fadeAccum += delta
		text.modulate.a = clamp(1.0 - fadeAccum / fadeTime, 0.0, 1.0)
		if fadeAccum >= fadeTime:
			queue_free()
