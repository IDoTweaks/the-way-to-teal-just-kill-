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
@export var slamDamage := 25
@export var slamRadius := 1
@export var slamHeight := 3.0
@export var jawOpen : float = .55
@export var rearPitch : float = .45
@export var bitePitch : float = .35
@export var slamKb : float = 12.0
@export var spinTime : float = 2.0
@export var spinSpeed : float = 9.0
@export var spinRadius : float = 3.4
@export var spinLag : float = .5
@export var spinDamage := 8
@export var spinKb : float = 15.0
@export var spinHitCd : float = .45
@export var whipHeight : float = 3.2
@export var whipUpTime : float = .35
@export var whipDownTime : float = .12
@export var ringSpeed : float = 11.7
@export var ringWidth : float = 1.3
@export var ringHeight : float = 1.0
@export var ringDamage := 15
@export var ringKb : float = 20.0
@export var ringMaxRadius : float = 24.0
@export var ringDoors : int = 3
@export var doorWidth : float = .42
@export var venomShots : int = 3
@export var venomGap : float = .22
@export var venomSpeed : float = 18.0
@export var venomDamage := 10
@export var venomKb : float = 8.0
var coiled :=false
var charging := false
var spinning := false
var spinT := 0.0
var spinHitNow := 0.0
var spinFxNow := 0.0
var spinCenter : Vector3
var rings : Array = []
var segms := []
var moving := false
@onready var orgY := []
var launching := false
var speedNow = baseLaunchSpeed
var launchStart : Vector3
var launchTarg : Vector3
var lockedTarg : Vector3
var launchT :=0.0
var trail : Array[Vector3] = []
#var tick := 0
@onready var jaw1 = $head/horn
@onready var jaw2 = $head/horn2
@onready var slamParticles = preload("res://Particles/slamImpact.tscn")
@onready var dustParticles = preload("res://Particles/landDust.tscn")
@onready var trailParticles = preload("res://Particles/dashTrail.tscn")
@onready var venomBall = preload("res://ObjectScenes/venomBall.tscn")
var jawBase1 : float
var jawBase2 : float
var marks : Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	segms = [$head,$hulia,$hulia2,$hulia3,$hulia4,$hulia5]
	for seg in segms:
		orgY.append(seg.global_position.y)
	jawBase1 = jaw1.rotation.y
	jawBase2 = jaw2.rotation.y
	var timer = Timer.new()
	timer.wait_time = tickTime
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_onTick)
	#_atkCharge()

func _onTick():
	if !moving and !coiled and !launching and !charging and !spinning:
		_step()
	#if tick < 10:
		#tick +=1
	#elif tick == 10:
		#_atkCharge()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		_charge()
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		_spin()
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		_venom()
		

func _charge():
	if charging or launching or coiled:
		return
	charging = true
	while moving:
		await get_tree().process_frame
	if await _prepCharge():
		_beginLaunch()
	charging = false

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
	if marks.is_empty():
		return
	var pulse = sin(Time.get_ticks_msec() * .012) * .5 + .5
	for m in marks:
		if is_instance_valid(m):
			m.material_override.emission_energy_multiplier = 1.2 + pulse * 3.2

func _prepCharge():
	if moving or coiled or player == null:
		return
	moving = true
	lockedTarg = player.global_position
	if bossFloor != null:
		var block = bossFloor._tileNode(lockedTarg.x,lockedTarg.z)
		if block != null:
			lockedTarg = Vector3(block.global_position.x,lockedTarg.y,block.global_position.z)
			_markBlocks(block)
	_openJaws()
	var head = segms[0]
	var dir = lockedTarg - head.global_position
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
	var  offset := Vector3(lockedTarg.x - head.global_position.x,0.0,lockedTarg.z - head.global_position.z)
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
	_updateRings(delta)
	if spinning:
		_spinStep(delta)
		velocity = Vector3.ZERO
		move_and_slide()
		return
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
			_slam()
	else:
		velocity = Vector3.ZERO
		move_and_slide()
	

func _markBlocks(block):
	_clearMarks()
	if bossFloor == null:
		return
	for t in bossFloor._tilesAround(block.global_position.x,block.global_position.z,slamRadius):
		var core = t == block
		var mark = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(.92,.05,.92)
		mark.mesh = box
		var mat = StandardMaterial3D.new()
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(.8,.35,1.0,.6) if core else Color(.5,.1,.9,.35)
		mat.emission_enabled = true
		mat.emission = Color(.7,.25,1.0)
		mark.material_override = mat
		get_parent().add_child(mark)
		mark.global_position = t.global_position + Vector3(0,.53,0)
		marks.append(mark)

func _clearMarks():
	for m in marks:
		if is_instance_valid(m):
			m.queue_free()
	marks.clear()

func _openJaws():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(jaw1,"rotation:y",jawBase1 + jawOpen,coilTime)
	tween.tween_property(jaw2,"rotation:y",jawBase2 - jawOpen,coilTime)
	tween.tween_property(segms[0],"rotation:z",-rearPitch,coilTime)

func _bite():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(jaw1,"rotation:y",jawBase1,.1)
	tween.tween_property(jaw2,"rotation:y",jawBase2,.1)
	tween.tween_property(segms[0],"rotation:z",bitePitch,.08)
	tween.chain().tween_property(segms[0],"rotation:z",0.0,.3)

func _slam():
	var head = segms[0]
	_bite()
	_clearMarks()
	var burst = slamParticles.instantiate()
	get_parent().add_child(burst)
	burst.global_position = head.global_position
	burst.emitting = true
	Audio.play("slam", .8, -2.0)
	if player == null or bossFloor == null:
		return
	if player.has_method("_addShake"):
		player._addShake(.1)
	var center = bossFloor._wrld2Tile(head.global_position.x,head.global_position.z)
	var pTile = bossFloor._wrld2Tile(player.global_position.x,player.global_position.z)
	if center.x == -1 or pTile.x == -1:
		return
	if abs(pTile.x - center.x) > slamRadius or abs(pTile.y - center.y) > slamRadius:
		return
	if abs(player.global_position.y - head.global_position.y) > slamHeight:
		return
	_hitPlayer(slamDamage,1,slamKb,head.global_position)

func _hitPlayer(dmg,para : int,force : float,from : Vector3):
	if player == null:
		return
	if player.has_method("_takeDamage"):
		player._takeDamage(dmg,from)
	if player.has_method("_paralyze"):
		player._paralyze(para)
	if player.has_method("_applyForce"):
		player._applyForce(from,force,ringMaxRadius)

func _spin():
	if charging or launching or coiled or spinning:
		return
	charging = true
	while moving:
		await get_tree().process_frame
	spinCenter = segms[0].global_position
	spinCenter.y = orgY[0]
	spinT = 0.0
	spinHitNow = 0.0
	spinFxNow = 0.0
	_openJaws()
	Audio.play("dash", .6, -4.0)
	spinning = true

func _spinStep(delta : float):
	spinT += delta
	var ang = spinT * spinSpeed
	for i in range(segms.size()):
		var a = ang - i * spinLag
		var rad = spinRadius * (.35 + .65 * (float(i) / float(segms.size() - 1)))
		var pos = spinCenter + Vector3(cos(a),0,sin(a)) * rad
		pos.y = orgY[i] + sin(spinT * 7.0 + i) * .12
		segms[i].global_position = pos
		segms[i].rotation.y = atan2(cos(a),sin(a))
	spinFxNow -= delta
	if spinFxNow <= 0:
		spinFxNow = .1
		var seg = segms[randi_range(0,segms.size() - 1)]
		var fx = trailParticles.instantiate()
		get_parent().add_child(fx)
		fx.global_position = seg.global_position
		fx.emitting = true
	spinHitNow -= delta
	if spinHitNow <= 0 and player != null:
		var flat = Vector2(player.global_position.x - spinCenter.x,player.global_position.z - spinCenter.z)
		if flat.length() < spinRadius and abs(player.global_position.y - spinCenter.y) < slamHeight:
			spinHitNow = spinHitCd
			if player.has_method("_addShake"):
				player._addShake(.07)
			_hitPlayer(spinDamage,1,spinKb,spinCenter)
	if spinT >= spinTime:
		spinning = false
		_tailWhip()

func _tailWhip():
	Audio.play("walljump", .5, -4.0)
	var up = create_tween()
	up.set_parallel(true)
	up.set_trans(Tween.TRANS_BACK)
	up.set_ease(Tween.EASE_OUT)
	for i in range(1,segms.size()):
		var t = float(i) / float(segms.size() - 1)
		up.tween_property(segms[i],"global_position:y",orgY[i] + whipHeight * t,whipUpTime)
	up.tween_property(segms[0],"rotation:z",-rearPitch,whipUpTime)
	await up.finished
	var down = create_tween()
	down.set_parallel(true)
	down.set_trans(Tween.TRANS_QUAD)
	down.set_ease(Tween.EASE_IN)
	for i in range(1,segms.size()):
		down.tween_property(segms[i],"global_position:y",orgY[i],whipDownTime)
	await down.finished
	_groundSlam()
	_bite()
	_reform()
	charging = false

func _groundSlam():
	Audio.play("slam", .6, 0.0)
	var burst = slamParticles.instantiate()
	get_parent().add_child(burst)
	burst.global_position = segms[segms.size() - 1].global_position
	burst.emitting = true
	var dust = dustParticles.instantiate()
	get_parent().add_child(dust)
	dust.global_position = spinCenter
	dust.emitting = true
	if player != null and player.has_method("_addShake"):
		player._addShake(.18)
	_spawnRing(spinCenter)

func _spawnRing(center : Vector3):
	var doors = []
	var base = randf() * TAU
	for d in range(ringDoors):
		doors.append(wrapf(base + TAU * float(d) / float(ringDoors),0,TAU))
	var holder = Node3D.new()
	get_parent().add_child(holder)
	holder.global_position = Vector3(center.x,center.y + .1,center.z)
	var pieces = []
	var slots = 72
	for i in range(slots):
		var a = TAU * float(i) / float(slots)
		if _inDoor(a,doors):
			continue
		var piece = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(.5,.16,.5)
		piece.mesh = box
		var mat = StandardMaterial3D.new()
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(.72,.28,1.0,.8)
		mat.emission_enabled = true
		mat.emission = Color(.65,.2,1.0)
		mat.emission_energy_multiplier = 3.5
		piece.material_override = mat
		holder.add_child(piece)
		pieces.append({"node":piece,"ang":a})
	rings.append({"holder":holder,"pieces":pieces,"doors":doors,"center":center,"r":1.0,"hit":false,"slots":slots})

func _inDoor(ang : float,doors) -> bool:
	for d in doors:
		if abs(wrapf(ang - d,-PI,PI)) < doorWidth:
			return true
	return false

func _updateRings(delta : float):
	for ring in rings.duplicate():
		var holder = ring["holder"]
		if !is_instance_valid(holder):
			rings.erase(ring)
			continue
		ring["r"] += ringSpeed * delta
		var r = ring["r"]
		var arc = TAU * r / float(ring["slots"])
		var fade = clamp(1.0 - (r / ringMaxRadius),0.0,1.0)
		for p in ring["pieces"]:
			var piece = p["node"]
			if !is_instance_valid(piece):
				continue
			var a = p["ang"]
			piece.position = Vector3(cos(a),0,sin(a)) * r
			piece.rotation.y = -a
			piece.scale = Vector3(1.0,1.0,max(arc / .5,1.0))
			piece.material_override.albedo_color.a = .8 * fade
		if !ring["hit"] and player != null:
			var center = ring["center"]
			var flat = Vector2(player.global_position.x - center.x,player.global_position.z - center.z)
			var dist = flat.length()
			if abs(dist - r) < ringWidth and abs(player.global_position.y - center.y) < ringHeight:
				var pAng = wrapf(atan2(flat.y,flat.x),0,TAU)
				if !_inDoor(pAng,ring["doors"]):
					ring["hit"] = true
					_hitPlayer(ringDamage,1,ringKb,center)
		if r >= ringMaxRadius:
			holder.queue_free()
			rings.erase(ring)

func _venom():
	if charging or launching or coiled or spinning or player == null:
		return
	charging = true
	while moving:
		await get_tree().process_frame
	_openJaws()
	await get_tree().create_timer(coilTime).timeout
	for i in range(venomShots):
		if player == null:
			break
		_spitVenom()
		await get_tree().create_timer(venomGap).timeout
	_bite()
	charging = false

func _spitVenom():
	var head = segms[0]
	var aim = player.global_position + Vector3(0,.4,0)
	var dir = aim - head.global_position
	dir.y = 0
	if dir.length() > .01:
		var yaw = atan2(dir.z,-dir.x)
		head.rotation.y = head.rotation.y + wrapf(yaw - head.rotation.y,-PI,PI)
	var forward = Vector3(-cos(head.rotation.y),0,sin(head.rotation.y))
	var spit = venomBall.instantiate()
	spit.dest = aim
	spit.speed = venomSpeed
	spit.damage = venomDamage
	spit.knockback = venomKb
	get_parent().add_child(spit)
	spit.global_position = head.global_position + forward * .8 + Vector3(0,.2,0)
	var fx = trailParticles.instantiate()
	get_parent().add_child(fx)
	fx.global_position = spit.global_position
	fx.emitting = true
	Audio.play("shotgun", .55, -7.0)

func _reform():
	var head = segms[0]
	var back = Vector3(cos(head.rotation.y),0,-sin(head.rotation.y))
	var tween = create_tween()
	tween.set_parallel(true)
	for i in range(1,segms.size()):
		var targ = head.global_position + back * (coilGap * i)
		targ.y = orgY[i]
		tween.tween_property(segms[i],"global_position",targ,.25).set_delay(i * jointDelay)

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
