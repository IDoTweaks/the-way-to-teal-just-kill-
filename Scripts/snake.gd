extends CharacterBody3D

@export var bossFloor : Node3D
@export var player : Node3D
@export var tickTime : float = .4
@export var stepTime : float = .15
@export var jointDelay : float = .04
@export var coilTime : float = .3
@export var coilGap  : float = .35
@export var rearUP : float = .8
@export var baseLaunchSpeed := 25
@export var launchMult := 5
@export var jumpTime := .7
@export var arcHeight := 3.5
var coiled :=false
var segms := []
var moving := false
@onready var orgY := []
var launching := false
var speedNow = baseLaunchSpeed
var launchStart : Vector3
var launchTarg : Vector3
var launchT :=0.0
var trail : Array[Vector3] = []
#var tick := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	segms = [$head,$hulia,$hulia2,$hulia3,$hulia4,$hulia5]
	for seg in segms:
		orgY.append(seg.global_position.y)
	var timer = Timer.new()
	timer.wait_time = tickTime
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_onTick)
	#_atkCharge()

func _onTick():
	if !moving and !coiled and !launching:
		_step()
	#if tick < 10:
		#tick +=1
	#elif tick == 10:
		#_atkCharge()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		_charge()
		

func _charge():
	await _prepCharge()
	_beginLaunch()

func _step():
	for i in range(segms.size()):
		#segms[i].global_position.y = orgY[i]
		var tween = create_tween()
		tween.tween_property(segms[i],"global_position:y",orgY[i],.5)
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

func _prepCharge():
	if moving or coiled:
		return
	moving = true
	var head = segms[0]
	var dir = player.global_position - head.global_position
	dir.y = 0
	var yaw = head.rotation.y
	if dir.length() > .01:
		yaw = atan2(dir.z, -dir.x)
		yaw = head.rotation.y + wrapf(yaw - head.rotation.y,-PI,PI)
	var back = Vector3(cos(yaw),0, -sin(yaw))
	var basePos = head.global_position
	var coilTween = create_tween()
	coilTween.set_parallel(true)
	coilTween.set_trans(Tween.TRANS_BACK)
	coilTween.set_ease(Tween.EASE_OUT)
	coilTween.tween_property(head, "rotation:y",yaw, coilTime)
	coilTween.tween_property(head,"global_position",basePos + back * coilGap * .5 + Vector3.UP * rearUP,coilTime)
	for i in range(1,segms.size()):
		var t = float(i) / float(segms.size()-1)
		var targ = basePos + back * (coilGap * i)
		targ.y = segms[i].global_position.y+ rearUP * (1.0 - t) * .5
		coilTween.tween_property(segms[i],"global_position",targ,coilTime).set_delay(i * jointDelay)
	await coilTween.finished
	coiled = true
	moving = false
	return true

func _beginLaunch():
	var head = segms[0]
	var  offset := Vector3(player.global_position.x - head.global_position.x,0.0,player.global_position.z - head.global_position.z)
	launchStart = global_position
	launchTarg = launchStart + offset
	launchT = 0.0
	var yaw := atan2(offset.z,-offset.x)
	head.rotation.y = head.rotation.y + wrapf(yaw - head.rotation.y,-PI,PI)
	trail.clear()
	for seg in segms:
		trail.append(seg.global_position)
	launching = true
	



func _launch(toX,toZ, speed,delta):
	var head = segms[0]
	var dir :Vector3 = Vector3(-head.global_position.x + toX,0,-head.global_position.z + toZ)
	if dir.length() > .1:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		var trailDir = -dir
		var yaw = atan2(dir.z,-dir.x)
		var headYaw = head.rotation.y + wrapf(yaw - head.rotation.y,-PI,PI)
		head.rotation.y = headYaw
		for i in range(1,segms.size()):
			var seg = segms[i]
			var targPos = head.global_position + (trailDir * (coilGap* i))
			targPos.y = orgY[i]
			#lineTween.tween_property(seg,"global_position",targPos,.5)
			var safeYaw = seg.rotation.y + wrapf(yaw - seg.rotation.y, -PI,PI)
			#lineTween.tween_property(seg,"rotation:y",safeYaw,.5)
			seg.global_position = targPos
			seg.rotation.y = safeYaw
			seg.rotation.y = headYaw
		speedNow = speed + launchMult * delta
	else:
		launching = false
		velocity.x = 0
		velocity.z = 0

func _physics_process(delta: float) -> void:
	if launching:
		launchT = min(launchT + delta / jumpTime,1.0)
		var t:= launchT
		var pos := launchStart.lerp(launchTarg,t)
		pos.y += 4.0 * arcHeight * t*(1.0 -t)
		velocity = (pos - global_position) / delta
		move_and_slide()
		_recordTrail()
		_followTrail()
		if t >= 1.0:
			launching = false
			coiled = false
			velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO
		move_and_slide()
	

func _recordTrail():
	var head = segms[0]
	if trail.is_empty() or trail[0].distance_to(head.global_position) > .05:
		trail.push_front(head.global_position)
		if trail.size() > 512:
			trail.resize(512)

func _trailPoint(dist :float):
	var travelled := 0.0
	for i in range(trail.size() -1):
		var a = trail[i]
		var b = trail[i + 1]
		var segLen := a.distance_to(b)
		if segLen <= .0001:
			continue
		if travelled + segLen >= dist:
			return a.lerp(b,((dist - travelled) / segLen))
		travelled += segLen
	return trail[trail.size() - 1]

func _followTrail():
	for i in range(1,segms.size()):
		var pos = _trailPoint(coilGap * i)
		segms[i].global_position = pos
		var d : Vector3 = segms[i-1].global_position - pos
		if d.length() > .001:
			var yaw := atan2(d.z,-d.x)
			segms[i].rotation.y = segms[i].rotation.y + wrapf(yaw - segms[i].rotation.y, -PI,PI)


func _occupied():
	var arr := []
	for seg in segms:
		arr.append(seg.global_position)
	return arr
