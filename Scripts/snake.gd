extends Node3D

@export var bossFloor : Node3D
@export var player : Node3D
@export var tickTime : float = .4
@export var stepTime : float = .15
@export var jointDelay : float = .04
var segms : Array = []
var moving := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	segms = [$head,$hulia,$hulia2,$hulia3,$hulia4,$hulia5]
	var timer = Timer.new()
	timer.wait_time = tickTime
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_onTick)

func _onTick():
	if !moving:
		_step()

func _step():
	if bossFloor == null || player == null:
		return
	var head = segms[0]
	var blockers = []
	for i in range(1,segms.size() - 1): #ignore the tail like real snakes
		blockers.append(segms[i].global_position)
	var nextTile = bossFloor._pathFind(head.global_position.x,head.global_position.z, player.global_position.x,player.global_position.z,blockers)
	if nextTile == null or !is_instance_valid(nextTile):
		return
	var targ = Vector3(nextTile.global_position.x,head.global_position.y,nextTile.global_position.z)
	if head.global_position.distance_to(targ) < 0.01:
		return
	moving = true
	var oldPos = []
	for seg in segms:
		oldPos.append(seg.global_position)
	#var headDelta = targ -head.global_position
	var dir = targ - head.global_position
	var yaw = atan2(dir.z, -dir.x)#idfk know this math its the power of google!
	yaw = head.rotation.y + wrapf(yaw - head.rotation.y,-PI,PI)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(head,"global_position",targ,stepTime)
	tween.tween_property(head,"rotation:y",yaw,stepTime)
	for i in range(1,segms.size()):
		tween.tween_property(segms[i],"global_position",oldPos[i-1],stepTime).set_delay(i * jointDelay)
	await tween.finished
	moving = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _occupied():
	var arr = []
	for seg in segms:
		arr.append(seg.global_position)
	return arr
