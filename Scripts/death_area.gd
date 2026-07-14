extends Area3D
@onready var deathRay : MeshInstance3D = $deathRay
var currDelt = 0.005
var targ = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	deathRay.visible = false

func _activate(type : int):
	await _warning(currDelt)
	if type == 1:
		_shoot()
	else:
		_removeSelf()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	currDelt = delta

func _removeSelf():
	get_parent().queue_free()

func _shoot():
	deathRay.visible = false
	if targ != null:
		targ._takeDamage(10000,self)
	

func _warning(delta: float):
	deathRay.transparency = 1.0
	deathRay.visible = true
	var tween = create_tween()
	tween.tween_property(deathRay,"transparency",0,2.5)
	await tween.finished
	#deathRay.transparency += .1 * delta
	#print(deathRay.transparency)
	#if deathRay.transparency >= 1:
	#	deathRay.visible = false
	#else:
	#	_warning(currDelt)



func _on_body_entered(body: Node3D) -> void:
	if body.has_method("_player"):
		targ = body


func _on_body_exited(body: Node3D) -> void:
	if body.has_method("_player"):
		targ = null
