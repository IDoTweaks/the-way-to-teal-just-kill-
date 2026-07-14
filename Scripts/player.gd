extends CharacterBody3D
func player():pass
func _player():pass
const SENS = 0.005;
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAXCAMSHAKE = 0.03
var shakeAmount : float = 0.0
var shakeDecay : float = 8.0
# juice
var camPitch : float = 0.0
var camRoll : float = 0.0
var camKickPitch : float = 0.0
@export var maxRoll : float = 0.05
@export var speedFovAdd : float = 18.0
var _hitStopUntil : float = 0.0
var _hurtFlash : float = 0.0
var _lastRankIdx : int = 0
var _crossDot : ColorRect
var _hitMark : Label
var _vignette : TextureRect
var _hitDir : Control
var _hitArrow : Label
@export var health = 100
var time = 0.0;
var count = true
@onready var maxScore = 0

#ghost
func ghost():pass
var positionSaves : Array[Vector3]
var posI : int
var rotationSaves : Array[Vector3]
var rotI : int
var camPositionSaves : Array[Vector3]
var camPosI : int
var camRotationSaves : Array[Vector3]
var camRotI : int
var weaponSaves : Array[int]

#sliding
var wasSliding: bool = false
var slide :bool = false
@export var downForceDevide: float
@export var slideFactor: float = 0.4
@export var slideDownforce: float = 20
#dashing
@export var dashBoost: float = 18
@export var dashCooldown: float = 0.6
var dashing: bool = false
var dashCdTimer: float = 0
var dashDir: Vector3 = Vector3.ZERO

const MAX_PARA = 10
@export var paraChipDmg : float = 4.0
@export var paraChipRate : float = 1.0
@export var paraDashMult : float = 0.5
var paraLevel : int = 0
var paraFlash : float = 0.0
var paraChipTimer : float = 0.0
var paraVignette : TextureRect

@onready var feet = $feetPos;
@onready var playerCam = $playerCam;
@onready var animaPlayer = $AnimationPlayer
@onready var gunRay = $playerCam/RayCast3D
@onready var shootingParticles =preload("res://Particles/shootParticles.tscn")
@onready var shotgunBlast = preload("res://Particles/shotgunBlast.tscn")
@onready var bulletImpactParticles = preload("res://Particles/bulletImpact.tscn")
@onready var slamParticles = preload("res://Particles/slamImpact.tscn")
@onready var dashParticles = preload("res://Particles/dashTrail.tscn")
@onready var wallJumpParticles = preload("res://Particles/wallJumpBurst.tscn")
@onready var hurtParticles = preload("res://Particles/playerHurt.tscn")
@onready var jumpParticles = preload("res://Particles/jumpPuff.tscn")
@onready var landParticles = preload("res://Particles/landDust.tscn")
@onready var finishParticles = preload("res://Particles/finishBurst.tscn")
@onready var groundSlam = preload("res://ObjectScenes/slamRIng.tscn")
@onready var gunParticleSpawn = $playerCam/gun/particleSpawnGun
@onready var rayContainer = $playerCam/rayContainer
@onready var gun = $playerCam/gun
@onready var shotGun = $playerCam/shotGun
@onready var shotgunDemo = $playerCam/gun/shotGunDemo
@onready var shotgunForcePnt = $playerCam/shotGun/shotGunForcePoint
@onready var leftArm = $playerCam/leftArm
@onready var rightArm = $playerCam/rightArm
@onready var scopeOverlay = $HUD/Scope
@onready var finishOrb = $"../FinishOrb"
@onready var levelEnd = $levelEnd
@onready var timer :Label = $HUD/timer
@onready var enemyCounter :Label = $HUD/enemyCounter
@onready var slamFrom = $body/slamFrom
var particleInstance

#general movement
var airAccel = 8
var coyoteTimer: float = 0
const COYOTE_TIME = 0.12
var jumpBuffer: float = 0
const JUMP_BUFFER_TIME = 0.12
var upDashed = false;
var knockbackTimer: float = 0.0
const KNOCKBACK_LOCK_TIME = 0.15
@export var slamVeloc = 25.0
var airTime :float = 0.0

# style system
var styleMeter : float = 0.0
var styleDecay : float = 9.0
var lastStyleAction : String = ""
var styleTimeAccum : float = 0.0
@export var comboWindow : float = 2.5
var lastKillTime : float = -999.0
var comboCount : int = 0
@onready var styleLabel : Label = $HUD/StyleMeterUI/styleRankLabel
@onready var styleBar : ProgressBar = $HUD/StyleMeterUI/styleBar
@onready var styleFire : ColorRect = $HUD/StyleMeterUI/Fire
@onready var healthBar : ColorRect = $HUD/healthBar
@onready var weaponSlots = [$HUD/WeaponIndicator/Slot0, $HUD/WeaponIndicator/Slot1, $HUD/WeaponIndicator/Slot2]

# wall jumping
var wallNormal  = Vector3.ZERO
var canWallJump = false
var wallJumpCd = 0
const WALL_JUMP_VELOCITY = 6
const WALL_JUMP_BOOST = 8
const WALL_JUMP_COOLDOWN= 0

#footprint system
@export var step_distance: float = 0.5
@export var decal_size: float = 0.4
@export var max_footprints: int = 120
var _last_footprint_pos: Vector3 = Vector3.ZERO
var _footprint_pool: Array[Node] = []
var _footprint_tex: ImageTexture

func _addStyle(action: String, amount: float):
	var pts = amount if lastStyleAction != action else amount * 0.35
	lastStyleAction = action
	styleMeter = clamp(styleMeter + pts, 0.0, 100.0)

func _onKill():
	var amount := 12.0
	if not is_on_floor():
		amount += 14.0
	var hspeed = Vector2(velocity.x, velocity.z).length()
	if hspeed > SPEED * 1.3:
		amount += clamp((hspeed - SPEED) * 1.2, 0.0, 16.0)
	if currentGun == 2:
		amount += 16.0
	var now = Time.get_ticks_msec() / 1000.0
	if now - lastKillTime <= comboWindow:
		comboCount += 1
		amount += float(comboCount) * 10.0
	else:
		comboCount = 0
	lastKillTime = now
	styleMeter = clamp(styleMeter + amount, 0.0, 100.0)
	lastStyleAction = "kill"
	_hitStop(0.05, 0.06)
	_hitmarker(true)
	Audio.play("pickup", 1.0 + min(comboCount, 8) * 0.07, -4.0)

func _getStyleRank() -> String:
	if styleMeter >= 97.0: return "SSS"
	if styleMeter >= 85.0: return "SS"
	if styleMeter >= 70.0: return "S"
	if styleMeter >= 55.0: return "A"
	if styleMeter >= 40.0: return "B"
	if styleMeter >= 22.0: return "C"
	return "D"

const STYLE_RANKS = ["D", "C", "B", "A", "S", "SS", "SSS"]

func _updateStyleHud():
	var rank = _getStyleRank()
	var rankIdx = STYLE_RANKS.find(rank)
	if rankIdx > _lastRankIdx:
		_rankPop(rankIdx)
	_lastRankIdx = rankIdx
	styleLabel.text = rank
	styleBar.value = styleMeter
	match rank:
		"D":  styleLabel.modulate = Color(0.55, 0.55, 0.55)
		"C":  styleLabel.modulate = Color(1.0, 1.0, 1.0)
		"B":  styleLabel.modulate = Color(1.0, 0.9, 0.15)
		"A":  styleLabel.modulate = Color(1.0, 0.5, 0.1)
		"S":  styleLabel.modulate = Color(1.0, 0.2, 0.2)
		"SS": styleLabel.modulate = Color(0.75, 0.2, 1.0)
		"SSS": styleLabel.modulate = Color(1.0, 0.85, 0.0)
	var fill = styleMeter / 100.0
	if styleFire.material:
		styleFire.material.set_shader_parameter("fill", fill)
	styleLabel.pivot_offset = styleLabel.size / 2.0
	var throb = 1.0 + 0.12 * fill * (sin(Time.get_ticks_msec() * 0.012) * 0.5 + 0.5)
	styleLabel.scale = Vector2(throb, throb)

func _make_teal_texture() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var ball_center = Vector2(32, 22)
	var ball_radii = Vector2(15, 17)
	var heel_center = Vector2(32, 46)
	var heel_radii = Vector2(10, 12)

	for x in range(64):
		for y in range(64):
			var p = Vector2(x, y)

			var ball_d = ((p.x - ball_center.x) / ball_radii.x) ** 2 + ((p.y - ball_center.y) / ball_radii.y) ** 2
			var heel_d = ((p.x - heel_center.x) / heel_radii.x) ** 2 + ((p.y - heel_center.y) / heel_radii.y) ** 2
			var inside_ball = ball_d <= 1.0
			var inside_heel = heel_d <= 1.0

			if not (inside_ball or inside_heel):
				continue

			var norm_d = min(ball_d, heel_d)

			var col: Color
			if norm_d < 0.35:
				col = Color(0.25, 0.95, 0.7, 0.95)
			elif norm_d < 0.7:
				var t = (norm_d - 0.35) / 0.35
				col = Color(0.11, 0.62, 0.46, 1).lerp(Color(0.06, 0.4, 0.3, 1), t)
				col.a = 0.9
			elif norm_d < 0.92:
				col = Color(0.04, 0.22, 0.17, 0.85)
			else:
				var t = clamp((norm_d - 0.92) / 0.18, 0.0, 1.0)
				col = Color(0.3, 1.0, 0.75, 1).lerp(Color(0.3, 1.0, 0.75, 0), t)

			var angle = p.angle_to_point(ball_center if inside_ball else heel_center)
			var streak = sin(angle * 10.0) * 0.08
			col.a = clamp(col.a + streak, 0.0, 1.0)

			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

func _spawn_footprint(pos: Vector3) -> void:
	var decal = Decal.new()
	decal.size = Vector3(decal_size, 0.5, decal_size)
	decal.texture_albedo = _footprint_tex
	decal.position = pos + Vector3(0, 0.05, 0)
	decal.modulate = Color(0.11, 0.62, 0.46, 0.85)
	get_parent().add_child(decal)
	_footprint_pool.append(decal)

	if _footprint_pool.size() > max_footprints:
		var oldest = _footprint_pool.pop_front()
		oldest.queue_free()

#gun
@export var damage : float = 10
@export var bullet_hole_size: float = 0.15
@export var max_bullet_holes: int = 100
@export var shotGunDmg : float = 4
@export var sniperDmg : float = 150
@export var sniperCooldown : float = 1.6
@onready var shotGunCdTimer = $shotGunCd
@onready var sniperGun = $playerCam/sniperGun
var sniperCdTimer : float = 0.0
@export var sniperRestRot : Vector3 = Vector3(0.22, 3.1415927, 0.18)
@export var hipfireSpread : float = 7.0
@export var scopedFov : float = 28.0
var scoped : bool = false
var fovTween : Tween
const SNIPER_REST_POS = Vector3(0.50524026, -0.12744474, -1.0080254)
const GUN_REST_POS = Vector3(0.388, -0.31, -0.652)
const GUN_REST_ROT = Vector3(-0.15707964, -3.2637658, 0.15707964)

var _bullet_pool: Array[Node] = []
var _bullet_tex: ImageTexture
var currentGun : int = 0
var unlockedGuns : int = 3
var shotGunCd = false
#0 - rifle
#1 - shotgun
#2 - sniper

var shotGunRestPos : Vector3
var shotGunRestRot : Vector3

var slamming = false
var slamStartHeight : float = 0.0

func _showGunModels():
	gun.visible = currentGun == 0
	shotGun.visible = currentGun == 1
	sniperGun.visible = currentGun == 2
	shotgunDemo.visible = false
	_updateWeaponHud()

func _switchGuns():
	if Input.is_action_just_pressed("gun1") and unlockedGuns > 0:
		currentGun = 0
		_showGunModels()
	elif Input.is_action_just_pressed("gun2") and unlockedGuns > 1:
		currentGun = 1
		_showGunModels()
	elif Input.is_action_just_pressed("gun3") and unlockedGuns > 2:
		currentGun = 2
		_showGunModels()

func _cycleGun(dir: int):
	currentGun = (currentGun + dir + unlockedGuns) % unlockedGuns
	_showGunModels()

func _setUnlockedGuns(n):
	unlockedGuns = clamp(n, 1, 3)
	currentGun = clamp(currentGun, 0, unlockedGuns - 1)
	_showGunModels()

func _updateWeaponHud():
	if weaponSlots == null:
		return
	for i in weaponSlots.size():
		var slot = weaponSlots[i]
		if slot == null:
			continue
		if i >= unlockedGuns:
			slot.modulate = Color(0.2, 0.24, 0.24, 0.4)
			slot.scale = Vector2.ONE
		elif i == currentGun:
			slot.modulate = Color(0, 1, 0.85, 1)
			slot.scale = Vector2(1.15, 1.15)
		else:
			slot.modulate = Color(0.55, 0.7, 0.68, 0.7)
			slot.scale = Vector2.ONE

func _tweenFov(target):
	if fovTween:
		fovTween.kill()
	fovTween = create_tween()
	fovTween.tween_property(playerCam, "fov", target, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _updateSniperView():
	var wantScope = currentGun == 2 and Input.is_action_pressed("scope")
	if wantScope != scoped:
		scoped = wantScope
		scopeOverlay.visible = scoped
		_tweenFov(scopedFov if scoped else Global.fov)
		if scoped:
			sniperGun.visible = false
			leftArm.visible = false
			rightArm.visible = false
		else:
			leftArm.visible = true
			rightArm.visible = true
			sniperGun.visible = currentGun == 2
	if not scoped and (fovTween == null or not fovTween.is_running()):
		var hspeed = Vector2(velocity.x, velocity.z).length()
		var add = clamp((hspeed - SPEED) / (SPEED * 2.0), 0.0, 1.0) * speedFovAdd
		playerCam.fov = lerp(playerCam.fov, Global.fov + add, 0.12)
	if currentGun == 2 and not scoped:
		if animaPlayer.current_animation == "sniperShoot":
			sniperGun.rotation = sniperRestRot
		else:
			sniperGun.position = SNIPER_REST_POS + (gun.position - GUN_REST_POS)
			sniperGun.rotation = sniperRestRot + (gun.rotation - GUN_REST_ROT)

func _die():
	count = false
	Engine.time_scale = 1.0
	$GameOver.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play("lose")
	
	

func _finishLevel():
	count = false
	Engine.time_scale = 1.0
	Audio.play("win")
	_spawnParticleAt(finishParticles, global_position)
	var earnedScore = maxScore - _calcMaxScore()
	var finalScore = clamp(earnedScore, 0, maxScore)
	var scorePercent = float(finalScore) / maxScore if maxScore > 0 else 0.0
	var avgStyle = styleTimeAccum / max(time, 1.0)
	var stylePercent = clamp(avgStyle / 100.0, 0.0, 1.0)
	var healthPercent = clamp(float(health) / 100.0, 0.0, 1.0)
	var gradeRating = scorePercent * 0.5 + stylePercent * 0.3 + healthPercent * 0.2
	var grade = _calcGrade(gradeRating * 100.0, 100.0)
	var displayScore = int(finalScore * (1.0 + stylePercent * 0.5))
	var lvl = Global.currentLevel
	Global._completeLevel(lvl)
	Global._recordTime(lvl, time)
	if displayScore > Global._ghostScore(lvl):
		Global._saveGhost(lvl, positionSaves.duplicate(), rotationSaves.duplicate(), camPositionSaves.duplicate(), camRotationSaves.duplicate(), weaponSaves.duplicate(), displayScore)
	levelEnd._setScore(displayScore)
	levelEnd._setGrade(grade)
	levelEnd._setLevel(lvl)
	levelEnd.visible = true

func _calcGrade(num, maxVal):
	if maxVal <= 0:
		return "S+" if num >= 0 else "F"
	if num >= maxVal:
		return "S+"
	var perecent = maxVal / 100.0
	if num >= (maxVal - 5 * perecent):
		return "S"
	if num >= (maxVal - 10 * perecent):
		return "S-"
	if num >= (maxVal - 15 * perecent):
		return "A+"
	if num >= (maxVal - 20 * perecent):
		return "A"
	if num >= (maxVal - 25 * perecent):
		return "A-"
	if num >= (maxVal - 30 * perecent):
		return "B+"
	if num >= (maxVal - 35 * perecent):
		return "B"
	if num >= (maxVal - 40 * perecent):
		return "B-"
	if num >= (maxVal - 45 * perecent):
		return "C+"
	if num >= (maxVal - 50 * perecent):
		return "C"
	if num >= (maxVal - 55 * perecent):
		return "C-"
	if num >= (maxVal - 60 * perecent):
		return "D+"
	if num >= (maxVal - 65 * perecent):
		return "D"
	if num >= (maxVal - 70 * perecent):
		return "D-"
	if num >= (maxVal - 75 * perecent):
		return "F"
	return "F"
	


func _make_bullet_texture() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	for x in range(64):
		for y in range(64):
			var d = Vector2(x, y).distance_to(center)
			if d < 10:
				img.set_pixel(x, y, Color(0.03, 0.18, 0.13, 1))
			elif d < 18:
				var t = (d - 10) / 8.0
				img.set_pixel(x, y, Color(0.11, 0.62, 0.46, 1 - t * 0.3))
			elif d < 28.0:
				var t = (d - 18) / 10
				img.set_pixel(x, y, Color(0.08, 0.45, 0.35, (1 - t) * 0.6))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

func _spawn_bullet_hole(pos: Vector3, normal: Vector3) -> void:
	var decal = Decal.new()
	decal.size = Vector3(bullet_hole_size, 1.0, bullet_hole_size)
	decal.texture_albedo = _bullet_tex
	decal.albedo_mix = 1.0
	decal.modulate = Color(1, 1, 1, 1)
	decal.position = pos + normal * 0.05
	var up = normal
	var right: Vector3
	if abs(up.dot(Vector3.UP)) < 0.99:
		right = Vector3.UP.cross(up).normalized()
	else:
		right = Vector3.RIGHT.cross(up).normalized()
	var forward = up.cross(right).normalized()
	decal.basis = Basis(right, up, forward)
	decal.rotate(normal, randf() * TAU)

	get_parent().add_child(decal)
	_bullet_pool.append(decal)

	if _bullet_pool.size() > max_bullet_holes:
		var oldest = _bullet_pool.pop_front()
		oldest.queue_free()

func _startDashAnim():
	if currentGun == 0:
		shotGun.visible = false
		gun.visible = true
		shotgunDemo.visible = false
	elif currentGun == 1:
		shotGun.visible = false
		gun.visible = true
		shotgunDemo.visible = true

func _startInSlide():
	if currentGun == 0:
		shotGun.visible = false
		gun.visible = true
		shotgunDemo.visible = false
	elif currentGun == 1:
		shotGun.visible = false
		gun.visible = true
		shotgunDemo.visible = true
	animaPlayer.play("inSlide")

func _shootAnim():
	if Input.is_action_pressed("shoot"):
		if currentGun == 0:
			shotGun.visible = false
			gun.visible = true
			animaPlayer.play("shootingAnim")
			particleInstance = shootingParticles.instantiate()
			particleInstance.position = gunParticleSpawn.global_position
			get_parent().add_child(particleInstance)
			particleInstance.emitting = true
		elif currentGun == 1:
			if !shotGunCd:
				shotGun.visible = true
				gun.visible = false
				animaPlayer.play("shotGunShoot")
				_spawnParticleAt(shotgunBlast, gunParticleSpawn.global_position)
		elif currentGun == 2:
			if Input.is_action_just_pressed("shoot") and sniperCdTimer <= 0:
				sniperGun.visible = true
				gun.visible = false
				shotGun.visible = false
				animaPlayer.play("sniperShoot")
				_spawnParticleAt(shotgunBlast, sniperGun.global_position)
	else:
		playerCam.position = Vector3();
		if animaPlayer.current_animation == "shootingAnim":
			animaPlayer.stop()
func _shoot():
	if currentGun == 0:
		_addShake(.01)
		Audio.play("rifle", 1.0, -5.0)
		playerCam.position = lerp(playerCam.position, Vector3(randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), 0), 0.5)
		if gunRay.is_colliding():
			var target = gunRay.get_collider()
			if target and target.has_method("_makeTarg"):
				target._makeTarg(self)
			if target and target.has_method("_damage"):
				_hitmarker(false)
				target._damage(damage)
			var hit_pos = gunRay.get_collision_point()
			var hit_normal = gunRay.get_collision_normal()
			_spawn_bullet_hole(hit_pos, hit_normal)
			_spawnParticleAt(bulletImpactParticles, hit_pos + hit_normal * 0.05)
			_draw_laser_line(gunParticleSpawn.global_position, gunRay.get_collision_point(), 0.25)
		else:
			var end_point = gunRay.to_global(gunRay.target_position)
			_draw_laser_line(gunParticleSpawn.global_position, end_point, 0.5)
	elif currentGun == 1:
		if !shotGunCd:
			_addShake(.04)
			Audio.play("shotgun", 1.0, -2.0)
			playerCam.position = lerp(playerCam.position, Vector3(randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), 0), 0.5)
			shotGunCd = true
			shotGunCdTimer.start()
			rayContainer.randomizeRays()
			for ray in rayContainer.get_children():
				if ray.is_colliding():
					var target = ray.get_collider()
					if target and target.has_method("_damage"):
						_hitmarker(false)
						target._damage(shotGunDmg)
					if target and target.has_method("_makeTarg"):
						target._makeTarg(self)
					var hit_pos = ray.get_collision_point()
					var hit_normal = ray.get_collision_normal()
					_spawn_bullet_hole(hit_pos, hit_normal)
					_spawnParticleAt(bulletImpactParticles, hit_pos + hit_normal * 0.05)
					_draw_laser_line(gunParticleSpawn.global_position, ray.get_collision_point(), 0.25)
				else:
					var end_point = ray.to_global(ray.target_position)
					_draw_laser_line(gunParticleSpawn.global_position, end_point, 0.5)
			_applyForce(shotgunForcePnt.global_position,10)
	elif currentGun == 2:
		if sniperCdTimer <= 0:
			Audio.play("shotgun", 0.7, -1.0)
			sniperCdTimer = sniperCooldown
			_addShake(.05 if scoped else .13)
			playerCam.position = lerp(playerCam.position, Vector3(randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), 0), 0.5)
			var camXform = playerCam.global_transform
			var origin = camXform.origin
			var forward = -camXform.basis.z
			if not scoped:
				var spread = deg_to_rad(hipfireSpread)
				forward = forward.rotated(camXform.basis.x.normalized(), randf_range(-spread, spread))
				forward = forward.rotated(camXform.basis.y.normalized(), randf_range(-spread, spread))
			var beamStart = sniperGun.global_position if sniperGun.visible else origin
			var far_point = origin + forward * 3000
			var space = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(origin, far_point)
			query.exclude = [self.get_rid()]
			var hit = space.intersect_ray(query)
			if hit:
				var target = hit.collider
				if target and target.has_method("_makeTarg"):
					target._makeTarg(self)
				if target and target.has_method("_damage"):
					_hitmarker(false)
					target._damage(sniperDmg)
				_spawn_bullet_hole(hit.position, hit.normal)
				_spawnParticleAt(bulletImpactParticles, hit.position + hit.normal * 0.05)
				_draw_laser_beam(beamStart, hit.position, 0.35)
			else:
				_draw_laser_beam(beamStart, far_point, 0.35)


func _applyForce(point :Vector3,force , maxRange:float = 10):
	var dir = global_position - point
	var dist = dir.length()
	if dist > maxRange:
		return
	dir = dir.normalized()
	var fallOff = clamp(1 - (dist/ maxRange),0,1)
	velocity += dir * force * fallOff
	knockbackTimer = KNOCKBACK_LOCK_TIME


func _draw_laser_line(from_pos: Vector3, to_pos: Vector3, duration: float = 0.1):
	var line_instance = MeshInstance3D.new()
	var imm_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	line_instance.mesh = imm_mesh
	
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0, 0.5, 1)
	line_instance.material_override = material
	
	imm_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	imm_mesh.surface_add_vertex(from_pos)
	imm_mesh.surface_add_vertex(to_pos)
	imm_mesh.surface_end()
	
	get_parent().add_child(line_instance)
	await get_tree().create_timer(duration).timeout
	line_instance.queue_free()

func _draw_laser_beam(from_pos: Vector3, to_pos: Vector3, duration: float = 0.35):
	var beam = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	var dist = from_pos.distance_to(to_pos)
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.05
	mesh.height = dist
	mesh.radial_segments = 10
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.6, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.65, 1.0)
	mat.emission_energy_multiplier = 6.0
	beam.mesh = mesh
	beam.material_override = mat
	get_parent().add_child(beam)
	if dist > 0.001:
		var ydir = (to_pos - from_pos).normalized()
		var xdir = ydir.cross(Vector3.UP)
		if xdir.length() < 0.01:
			xdir = ydir.cross(Vector3.RIGHT)
		xdir = xdir.normalized()
		var zdir = xdir.cross(ydir).normalized()
		beam.global_transform = Transform3D(Basis(xdir, ydir, zdir), (from_pos + to_pos) * 0.5)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration)
	tw.tween_property(beam, "scale", Vector3(0.15, 1.0, 0.15), duration)
	await get_tree().create_timer(duration).timeout
	beam.queue_free()

func _ready() -> void:
	maxScore = _calcMaxScore()
	finishOrb.open = true
	finishOrb.canvas =$levelEnd
	playerCam.fov = Global.fov
	Global._addTry(Global.currentLevel)
	if not OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_footprint_tex = _make_teal_texture()
	_last_footprint_pos = global_position
	_bullet_tex = _make_bullet_texture()
	_updateHud()
	_updateWeaponHud()
	_buildJuiceHud()
	shotGunRestPos = shotGun.position
	shotGunRestRot = shotGun.rotation


func _process(delta: float) -> void:
	if count:
		time +=  delta
		timer.text = str(int(time))
		styleMeter = clamp(styleMeter - styleDecay * delta, 0.0, 100.0)
		styleTimeAccum += styleMeter * delta
	enemyCounter.text = "ENEMIES %d" % get_tree().get_nodes_in_group("enemies").size()
	_updateStyleHud()
	#call input functions
	_shootAnim()
	_updateSniperView()

	if shakeAmount > 0:
		playerCam.position += Vector3(randf_range(-shakeAmount,shakeAmount),randf_range(-shakeAmount,shakeAmount),0)
		shakeAmount = move_toward(shakeAmount,0,shakeDecay * delta)
	var strafe = Input.get_axis("left", "right")
	var rollMul = 0.25 if scoped else 1.0
	camRoll = lerp(camRoll, -strafe * maxRoll * rollMul, delta * 8.0)
	camKickPitch = lerp(camKickPitch, 0.0, delta * 8.0)
	playerCam.rotation.x = camPitch + camKickPitch
	playerCam.rotation.z = camRoll
	_updateJuice(delta)
	_reloadVisual()
	#NOTE-use only when unhandles input isnt good enough
	
func _unhandled_input(event: InputEvent) -> void:
	_switchGuns()
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycleGun(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycleGun(-1)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens = Global.scopedSens if scoped else Global.sensitivity
		rotate_y(-event.relative.x * sens)
		camPitch = clamp(camPitch - event.relative.y * sens, deg_to_rad(-90), deg_to_rad(90))
		
	if Input.is_action_just_pressed("jump"):
		jumpBuffer = JUMP_BUFFER_TIME

	if event is InputEventKey and event.pressed and !event.echo:
		if event.keycode == KEY_P:
			_paralyze(1)
			print("para ", paraLevel)
		elif event.keycode == KEY_O:
			_curePara(1, 5)
			print("para ", paraLevel)

func _calcDownForce():
	#calculate the position in the future
	var horizontalVel = Vector3(velocity.x,0,velocity.z)
	var future = feet.global_position + horizontalVel
	
	#raycast prep
	var spaceState = get_world_3d().direct_space_state
	#starting above the future pos in case of upward slopes
	var rayStart = future + Vector3(0,1,0)
	var rayEnd = future + Vector3(0,-5,0)
	
	#setUp rayCast
	var rayQuery = PhysicsRayQueryParameters3D.create(rayStart,rayEnd)
	#so we dont hit ourselves xd
	rayQuery.exclude = [self.get_rid()]
	#now lets shoot this bad boyyy
	var intersect = spaceState.intersect_ray(rayQuery)
	
	#results time!!!!
	if intersect:
		#we want to return the distance from now to the future
		return feet.global_position.y - intersect.position.y
	else:
		#if it hits nothing we are fucking flying lets return so fucking much
		return 0

func _physics_process(delta: float) -> void:
	#THIS IS FOR THE GHOST DO NOT PUT CODE BEFORE
	positionSaves.insert(posI,global_position)
	posI+=1
	rotationSaves.insert(rotI,global_rotation)
	rotI+=1
	camPositionSaves.insert(camPosI,playerCam.global_position)
	camPosI+=1
	camRotationSaves.insert(camRotI,playerCam.global_rotation)
	camRotI+=1
	weaponSaves.append(currentGun)
	
	if knockbackTimer > 0:
		knockbackTimer -= delta
	if dashCdTimer > 0:
		dashCdTimer -= delta
	if sniperCdTimer > 0:
		sniperCdTimer -= delta
	if jumpBuffer > 0:
		jumpBuffer -= delta
	if wallJumpCd > 0:
		wallJumpCd -= delta
		
	if is_on_floor():
		if slamming == true:
			_spawnSlam()
		if airTime > 0.35:
			_spawnParticleAt(landParticles, feet.global_position)
			_landImpact(airTime)
		coyoteTimer = COYOTE_TIME
		slamming = false
		dashing = false
		upDashed = false
		airTime = 0.0
	elif coyoteTimer > 0:
		coyoteTimer -= delta
		
	
	_paraChip(delta)
	if knockbackTimer <= 0:
		slide = Input.is_action_pressed("slide") and _canSlide()
		if slide and not wasSliding:
			_addStyle("slide", 6)
			if is_on_floor():
				animaPlayer.play("slide")
				var currentDir = Vector3(velocity.x,0,velocity.z).normalized()
				if currentDir.length() > 0.1:
					velocity.x += currentDir.x * 6
					velocity.z += currentDir.z * 6
			elif slamming == false:
				slamming = true
				slamStartHeight = global_position.y
				animaPlayer.play("slam")
		wasSliding = slide
		if !slide:
			if animaPlayer.current_animation == "inSlide":
				animaPlayer.stop()
	
		if Input.is_action_just_pressed("dash") and dashCdTimer <= 0 and _canDash():
			_addStyle("dash", 9)
			Audio.play("dash", 1.0, -3.0)
			animaPlayer.play("dash")
			_spawnParticleAt(dashParticles, global_position)
			var input_dir := Input.get_vector("left", "right", "forward", "backward")
			var camForw = -playerCam.global_transform.basis.z
			var camRight = playerCam.global_transform.basis.x
			var fullDir: Vector3
			if input_dir.length() > 0.1:
				fullDir = (camRight * input_dir.x - camForw * input_dir.y).normalized()
			else:
				fullDir = camForw.normalized()
			dashDir = Vector3(fullDir.x,0,fullDir.z).normalized()
			dashCdTimer = dashCooldown
			var dashPow = _dashPower()
			if paraLevel < 1:
				if velocity.y < 0:
					velocity.y = 0
				velocity.y += fullDir.y * dashPow
			velocity.x = fullDir.x * dashPow
			velocity.z = fullDir.z * dashPow
		if is_on_floor():
			velocity += get_gravity()* delta;
	if knockbackTimer <= 0:
		if jumpBuffer > 0 and canWallJump and !is_on_floor() and wallJumpCd <= 0 and _canWallJump():
			_addStyle("walljump", 13)
			Audio.play("walljump", 1.0, -3.0)
			_spawnParticleAt(wallJumpParticles, global_position)
			var bounced = velocity.bounce(wallNormal)
			velocity.x = bounced.x * .4 + wallNormal.x *WALL_JUMP_BOOST
			velocity.z = bounced.z * .4 + wallNormal.z *WALL_JUMP_BOOST
			velocity.y = WALL_JUMP_VELOCITY
			wallJumpCd = WALL_JUMP_COOLDOWN
			jumpBuffer = 0
			upDashed = false
			
		if jumpBuffer > 0 and coyoteTimer > 0 and _canJump():
			coyoteTimer = 0.0
			jumpBuffer = 0.0
			velocity.y = JUMP_VELOCITY * _jumpMult()
			Audio.play("jump", 1.0, -7.0)
			_spawnParticleAt(jumpParticles, feet.global_position)
		
	if not is_on_floor() and Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= 0.45
		
	if not is_on_floor():
		airTime += delta
		velocity += get_gravity() * delta
	if knockbackTimer <= 0:
		if not slide:
			if Input.is_action_just_pressed("jump") and coyoteTimer > 0 and _canJump():
				coyoteTimer = 0.0
				velocity.y = JUMP_VELOCITY * _jumpMult()
				Audio.play("jump", 1.0, -7.0)
				_spawnParticleAt(jumpParticles, feet.global_position)

			var input_dir := Input.get_vector("left", "right", "forward", "backward")
			var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			var horizontal_speed = Vector2(velocity.x, velocity.z).length()
			var moveSpeed = SPEED * _speedMult()

			if is_on_floor():
				if direction:
					var accel = 30.0 if horizontal_speed < moveSpeed else 10.0
					velocity.x = move_toward(velocity.x, direction.x * moveSpeed, accel * delta)
					velocity.z = move_toward(velocity.z, direction.z * moveSpeed, accel * delta)
				else:
					velocity.x = move_toward(velocity.x, 0, 28 * delta)
					velocity.z = move_toward(velocity.z, 0, 28 * delta)

			else:
				if direction:
					velocity.x += direction.x * airAccel * _airMult() * delta
					velocity.z += direction.z * airAccel * _airMult() * delta
					var horizontal = Vector2(velocity.x, velocity.z)
					var cap = max(SPEED * 1.5, horizontal_speed) 
					if horizontal.length() > cap:
						horizontal = horizontal.normalized() * cap
						velocity.x = horizontal.x
						velocity.z = horizontal.y
				else:
					velocity.x = move_toward(velocity.x, 0, 2 * delta)
					velocity.z = move_toward(velocity.z, 0, 2 * delta)
					
		else:
			var force = _calcDownForce()
			var slideMod = clamp(slideFactor + (force / downForceDevide), 0, 2.5)
			if force > 0:
				velocity.y = -force * slideDownforce
				
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				
			var input_dir := Input.get_vector("left", "right", "forward", "backward")
			var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			var slide_accel = 5
			if direction:
				var target_x = direction.x * SPEED * slideMod
				var target_z = direction.z * SPEED * slideMod
				var current_h = Vector2(velocity.x, velocity.z).length()
				var target_h = Vector2(target_x, target_z).length()
				if target_h < current_h:
					var scale = current_h / max(target_h, 0.001)
					target_x *= scale
					target_z *= scale
				velocity.x = lerp(velocity.x, target_x, slide_accel * delta)
				velocity.z = lerp(velocity.z, target_z, slide_accel * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, 2.0 * delta)
				velocity.z = move_toward(velocity.z, 0, 2.0 * delta)
	
	if is_on_floor():
		var flat_pos = Vector3(global_position.x, 0, global_position.z)
		var flat_last = Vector3(_last_footprint_pos.x, 0, _last_footprint_pos.z)
		if flat_pos.distance_to(flat_last) >= step_distance:
			var side = (_footprint_pool.size() % 2) * 2 - 1
			var perp = transform.basis.x * 0.15 * side
			_spawn_footprint(feet.global_position + perp)
			Audio.footstep()
			_last_footprint_pos = global_position
	if slamming:
		velocity.y = -slamVeloc
	move_and_slide()
	_checkWall()

func _updateHud():
	if healthBar.material:
		healthBar.material.set_shader_parameter("health", clamp(health / 100.0, 0.0, 1.0))


func _takeDamage(damage, source = null):
	if count:
		_addShake(.06)
		_spawnParticleAt(hurtParticles, global_position)
		Audio.play("player_hurt")
		health -= damage
		_hurtFlash = 0.6
		if source != null:
			_showHitDir(source)
		_updateHud()
		if health <= 0:
			_die()

func _paralyze(amount : int = 1):
	if !count or paraLevel >= MAX_PARA:
		return
	paraLevel = min(paraLevel + amount, MAX_PARA)
	paraFlash = 0.7
	_addShake(.05)
	Audio.play("player_hurt", 0.6, -5.0)
	if paraLevel >= MAX_PARA:
		_die()

func _curePara(amount : int = 1, healthCost : float = 0.0):
	if paraLevel <= 0 or health <= healthCost:
		return false
	paraLevel = max(paraLevel - amount, 0)
	if healthCost > 0:
		health -= healthCost
		_updateHud()
	Audio.play("pickup", 1.2, -2.0)
	return true

func _canDash():
	return paraLevel < 2

func _canSlide():
	return paraLevel < 3

func _canWallJump():
	return paraLevel < 4

func _canJump():
	return paraLevel < 8

func _dashPower():
	if paraLevel >= 1:
		return SPEED + (dashBoost - SPEED) * paraDashMult
	return dashBoost

func _jumpMult():
	return 0.6 if paraLevel >= 5 else 1.0

func _airMult():
	return 0.0 if paraLevel >= 6 else 1.0

func _speedMult():
	if paraLevel >= 9:
		return 0.25
	if paraLevel >= 7:
		return 0.6
	return 1.0

func _paraChip(delta : float):
	if paraLevel < 9 or !count:
		return
	paraChipTimer -= delta
	if paraChipTimer <= 0:
		paraChipTimer = paraChipRate
		_takeDamage(paraChipDmg)

func _hitStop(scale : float, dur : float):
	Engine.time_scale = scale
	_hitStopUntil = Time.get_ticks_msec() + dur * 1000.0

func _reloadProgress() -> float:
	if currentGun == 1 and shotGunCd:
		var wt = shotGunCdTimer.wait_time
		if wt > 0:
			return 1.0 - shotGunCdTimer.time_left / wt
	if currentGun == 2 and sniperCdTimer > 0 and sniperCooldown > 0:
		return 1.0 - sniperCdTimer / sniperCooldown
	return -1.0

func _reloadVisual():
	var prog = _reloadProgress()
	if prog < 0.0:
		return
	var dip = sin(clamp(prog, 0.0, 1.0) * PI)
	var posOff = Vector3(0, -dip * 0.13, dip * 0.05)
	var rotOff = Vector3(dip * 0.7, 0, sin(prog * TAU) * 0.35)
	if currentGun == 1 and animaPlayer.current_animation != "shotGunShoot":
		shotGun.position = shotGunRestPos + posOff
		shotGun.rotation = shotGunRestRot + rotOff
	elif currentGun == 2 and animaPlayer.current_animation != "sniperShoot":
		sniperGun.position = SNIPER_REST_POS + posOff
		sniperGun.rotation = sniperRestRot + rotOff

func _landImpact(at : float):
	var f = clamp(at / 0.6, 0.0, 1.0)
	_addShake(0.02 + f * 0.06)
	camKickPitch = -0.06 * f

func _buildJuiceHud():
	var hud = $HUD
	_vignette = TextureRect.new()
	_vignette.texture = _make_vignette_texture()
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate = Color(1, 1, 1, 0)
	hud.add_child(_vignette)
	paraVignette = TextureRect.new()
	paraVignette.texture = _makeParaTexture()
	paraVignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paraVignette.stretch_mode = TextureRect.STRETCH_SCALE
	paraVignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	paraVignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paraVignette.modulate = Color(1, 1, 1, 0)
	hud.add_child(paraVignette)
	_crossDot = ColorRect.new()
	_crossDot.color = Color(0, 1, 0.85, 0.8)
	_crossDot.set_anchors_preset(Control.PRESET_CENTER)
	_crossDot.size = Vector2(5, 5)
	_crossDot.position = Vector2(-2.5, -2.5)
	_crossDot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_crossDot)
	_hitMark = Label.new()
	_hitMark.text = "X"
	_hitMark.set_anchors_preset(Control.PRESET_CENTER)
	_hitMark.add_theme_font_size_override("font_size", 26)
	_hitMark.position = Vector2(-9, -18)
	_hitMark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hitMark.modulate = Color(1, 1, 1, 0)
	hud.add_child(_hitMark)
	_hitDir = Control.new()
	_hitDir.set_anchors_preset(Control.PRESET_CENTER)
	_hitDir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hitDir.modulate = Color(1, 1, 1, 0)
	hud.add_child(_hitDir)
	_hitArrow = Label.new()
	_hitArrow.text = "^"
	_hitArrow.add_theme_font_size_override("font_size", 40)
	_hitArrow.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	_hitArrow.position = Vector2(-12, -140)
	_hitDir.add_child(_hitArrow)

func _hitmarker(killed : bool):
	if _hitMark == null:
		return
	_hitMark.modulate = Color(0, 1, 0.85, 1) if killed else Color(1, 1, 1, 0.9)
	_hitMark.pivot_offset = _hitMark.size / 2.0
	_hitMark.scale = Vector2(1.6, 1.6) if killed else Vector2(1.1, 1.1)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_hitMark, "modulate:a", 0.0, 0.28)
	tw.tween_property(_hitMark, "scale", Vector2(0.8, 0.8), 0.28)

func _showHitDir(source):
	if _hitDir == null:
		return
	var srcPos = source if source is Vector3 else source.global_position
	var toSrc = srcPos - global_position
	var basis = playerCam.global_transform.basis
	var ang = atan2(toSrc.dot(basis.x), toSrc.dot(-basis.z))
	_hitDir.rotation = ang
	_hitDir.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(_hitDir, "modulate:a", 0.0, 0.9)

func _rankPop(idx : int):
	if styleLabel:
		styleLabel.pivot_offset = styleLabel.size / 2.0
		styleLabel.scale = Vector2(1.8, 1.8)
	Audio.play("pickup", 0.9 + idx * 0.12, -2.0)

func _updateJuice(delta : float):
	if _hitStopUntil > 0.0 and Time.get_ticks_msec() >= _hitStopUntil:
		Engine.time_scale = 1.0
		_hitStopUntil = 0.0
	_hurtFlash = move_toward(_hurtFlash, 0.0, delta * 1.8)
	paraFlash = move_toward(paraFlash, 0.0, delta * 1.4)
	if _vignette:
		var lowHp = clamp((40.0 - health) / 40.0, 0.0, 1.0) * 0.45
		var pulse = (sin(Time.get_ticks_msec() * 0.008) * 0.5 + 0.5) * 0.2 if health < 25 else 0.0
		_vignette.modulate.a = clamp(lowHp + pulse + _hurtFlash, 0.0, 0.85)
	if paraVignette:
		var f = float(paraLevel) / float(MAX_PARA)
		paraVignette.modulate.a = clamp(f * 0.6 + paraFlash, 0.0, 0.85)

func _make_vignette_texture() -> ImageTexture:
	var s = 128
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c = Vector2(s * 0.5, s * 0.5)
	var maxd = c.length()
	for x in range(s):
		for y in range(s):
			var d = Vector2(x, y).distance_to(c) / maxd
			var a = clamp((d - 0.55) / 0.45, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.95, 0.05, 0.05, a * a))
	return ImageTexture.create_from_image(img)

func _makeParaTexture() -> ImageTexture:
	var s = 128
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c = Vector2(s * 0.5, s * 0.5)
	var maxd = c.length()
	for x in range(s):
		for y in range(s):
			var d = Vector2(x, y).distance_to(c) / maxd
			var a = clamp((d - 0.45) / 0.55, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.5, 0.12, 0.85, a * a))
	return ImageTexture.create_from_image(img)

func _spawnSlam():
	_addShake(.08)
	Audio.play("slam", 1.0, 0.0)
	var slam = groundSlam.instantiate()
	get_parent().add_child(slam)
	slam.global_position = feet.global_position
	_spawnParticleAt(slamParticles, feet.global_position)
	var fallHeight = slamStartHeight - global_position.y
	slam.damage = clamp(fallHeight * 3.0, 1.0, 60.0)
	_addStyle("slam", clamp(fallHeight * 3.0, 0.0, 28.0))

#func here so i can jump here fast
func wallJump():pass

func _addShake(amount : float):
	shakeAmount = max(shakeAmount, amount)

func _spawnParticleAt(scene, pos : Vector3):
	var p = scene.instantiate()
	get_parent().add_child(p)
	p.global_position = pos
	p.emitting = true

func _checkWall():
	if is_on_floor():
		canWallJump = false
		return
	
	if abs(velocity.x) + abs(velocity.z) > 1:
		var veloc = Vector3(velocity.x,0,velocity.z)
		#var future = self.global_position + veloc
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_normal().y < .3:
				wallNormal = collision.get_normal()
				canWallJump = true
				return
				
		
		if veloc.length() > 0.5:
			var spaceState = get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.create(global_position,global_position + veloc.normalized() * 1.2)
			ray.exclude = [self.get_rid()]
			var hit = spaceState.intersect_ray(ray)
			if hit and hit.normal.y < .3:
				wallNormal = hit.normal
				canWallJump = true
				return
		
		var altVeloc = Vector3(-velocity.x,0,velocity.z)
		if altVeloc.length() > 0.5:
			var spaceState = get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.create(global_position,global_position + altVeloc.normalized() * 1.2)
			ray.exclude = [self.get_rid()]
			var hit = spaceState.intersect_ray(ray)
			if hit and hit.normal.y < .3:
				wallNormal = hit.normal
				canWallJump = true
				return
		altVeloc = Vector3(velocity.x,0,-velocity.z)
		if altVeloc.length() > 0.5:
			var spaceState = get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.create(global_position,global_position + altVeloc.normalized() * 1.2)
			ray.exclude = [self.get_rid()]
			var hit = spaceState.intersect_ray(ray)
			if hit and hit.normal.y < .3:
				wallNormal = hit.normal
				canWallJump = true
				return
	else:
		var veloc = Vector3(1,0,1)
		#var future = self.global_position + veloc
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_normal().y < .3:
				wallNormal = collision.get_normal()
				canWallJump = true
				return
				
		
		if veloc.length() > 0.5:
			var spaceState = get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.create(global_position,global_position + veloc.normalized() * 1.2)
			ray.exclude = [self.get_rid()]
			var hit = spaceState.intersect_ray(ray)
			if hit and hit.normal.y < .3:
				wallNormal = hit.normal
				canWallJump = true
				return
		
		var altVeloc = Vector3(-1,0,1)
		if altVeloc.length() > 0.5:
			var spaceState = get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.create(global_position,global_position + altVeloc.normalized() * 1.2)
			ray.exclude = [self.get_rid()]
			var hit = spaceState.intersect_ray(ray)
			if hit and hit.normal.y < .3:
				wallNormal = hit.normal
				canWallJump = true
				return
		altVeloc = Vector3(1,0,-1)
		if altVeloc.length() > 0.5:
			var spaceState = get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.create(global_position,global_position + altVeloc.normalized() * 1.2)
			ray.exclude = [self.get_rid()]
			var hit = spaceState.intersect_ray(ray)
			if hit and hit.normal.y < .3:
				wallNormal = hit.normal
				canWallJump = true
				return
	
	
	
	canWallJump = false

func _calcMaxScore():
	var max = _calcMaxScoreRecursion(self.get_parent_node_3d())
	return max

func _calcMaxScoreRecursion(body):
	var total = 0
	if body.get("scoreWorth") != null:
		total += body.scoreWorth
	for child in body.get_children():
		total += _calcMaxScoreRecursion(child)
	return total
func _on_shot_gun_cd_timeout() -> void:
	shotGunCd = false
