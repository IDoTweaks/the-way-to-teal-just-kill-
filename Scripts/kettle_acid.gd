extends Node3D

@export var damage : float = 6.0
@export var tickTime : float = .5
@export var lifeTime : float = 6.0
@export var growTime : float = .3

var t : float = 0.0
var tickCd : float = 0.0
var inside : Array = []
var orgScale : Vector3
var fading = false

func _ready() -> void:
	orgScale = scale
	scale = Vector3(orgScale.x * .1, orgScale.y, orgScale.z * .1)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", orgScale, growTime)
	Audio.play("shotgun", 1.9, -24.0)

func _process(delta: float) -> void:
	if fading:
		return
	t += delta
	if t >= lifeTime:
		_fade()
		return
	tickCd -= delta
	if tickCd <= 0.0:
		tickCd = tickTime
		_tick()

func _tick():
	for b in inside:
		if is_instance_valid(b) and b.has_method("_takeDamage"):
			b._takeDamage(damage, global_position)

func _fade():
	fading = true
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector3(orgScale.x * .05, orgScale.y, orgScale.z * .05), .3)
	await tw.finished
	queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("player") and !inside.has(body):
		inside.append(body)
		Audio.play("player_hurt", 1.6, -16.0)

func _on_area_3d_body_exited(body: Node3D) -> void:
	inside.erase(body)
