extends CharacterBody3D
func player():pass
func _player():pass
const SENS = 0.005;
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAXCAMSHAKE = 0.03
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

@onready var feet = $feetPos;
@onready var playerCam = $playerCam;
@onready var animaPlayer = $AnimationPlayer
@onready var gunRay = $playerCam/RayCast3D
@onready var shootingParticles =preload("res://Particles/shootParticles.tscn")
@onready var gunParticleSpawn = $playerCam/gun/particleSpawnGun
@onready var rayContainer = $playerCam/rayContainer
@onready var gun = $playerCam/gun
@onready var shotGun = $playerCam/shotGun
@onready var shotgunDemo = $playerCam/gun/shotGunDemo
@onready var shotgunForcePnt = $playerCam/shotGun/shotGunForcePoint
@onready var finishOrb = $"../FinishOrb"
@onready var levelEnd = $levelEnd
@onready var timer :Label = $HUD/timer
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

func _make_teal_texture() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Sole shape: two overlapping ellipses (ball of foot + heel),
	# offset along Y to form a basic shoe-sole silhouette.
	var ball_center = Vector2(32, 22)
	var ball_radii = Vector2(15, 17)
	var heel_center = Vector2(32, 46)
	var heel_radii = Vector2(10, 12)

	for x in range(64):
		for y in range(64):
			var p = Vector2(x, y)

			# normalized distance into each ellipse (1.0 = on edge, 0 = center)
			var ball_d = ((p.x - ball_center.x) / ball_radii.x) ** 2 + ((p.y - ball_center.y) / ball_radii.y) ** 2
			var heel_d = ((p.x - heel_center.x) / heel_radii.x) ** 2 + ((p.y - heel_center.y) / heel_radii.y) ** 2
			var inside_ball = ball_d <= 1.0
			var inside_heel = heel_d <= 1.0

			if not (inside_ball or inside_heel):
				continue

			# pick whichever shape we're closer to the center of, for shading
			var norm_d = min(ball_d, heel_d)

			var col: Color
			if norm_d < 0.35:
				# bright glowing core
				col = Color(0.25, 0.95, 0.7, 0.95)
			elif norm_d < 0.7:
				# mid teal body
				var t = (norm_d - 0.35) / 0.35
				col = Color(0.11, 0.62, 0.46, 1).lerp(Color(0.06, 0.4, 0.3, 1), t)
				col.a = 0.9
			elif norm_d < 0.92:
				# darker inner rim before the edge glow
				col = Color(0.04, 0.22, 0.17, 0.85)
			else:
				# bright outer rim glow, then fade to transparent past d=1.0
				var t = clamp((norm_d - 0.92) / 0.18, 0.0, 1.0)
				col = Color(0.3, 1.0, 0.75, 1).lerp(Color(0.3, 1.0, 0.75, 0), t)

			# subtle radial streaks for a "scanned/etched" tech look
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
@onready var shotGunCdTimer = $shotGunCd

var _bullet_pool: Array[Node] = []
var _bullet_tex: ImageTexture
var currentGun : int = 0
var shotGunCd = false
#0 - rifle
#1 - shotgun

func _switchGuns():
	if Input.is_action_just_pressed("gun1"):
		currentGun = 0
		shotGun.visible = false
		gun.visible = true
		shotgunDemo.visible = false
	elif Input.is_action_just_pressed("gun2"):
		shotgunDemo.visible = false
		currentGun = 1
		shotGun.visible = true
		gun.visible = false
	elif Input.is_action_just_pressed("scrollUp"):
		if currentGun >= 1:
			currentGun = 0
		else:
			currentGun +=1

func _finishLevel():
	Global.positionSave = positionSaves.duplicate()
	Global.rotationSave = rotationSaves.duplicate()
	Global.camPositionSave = camPositionSaves.duplicate()
	Global.camRotationSave = camRotationSaves.duplicate()
	count = false
	var perfectTime = $"..".perfectTime
	var earnedScore = maxScore - _calcMaxScore()
	var finalScore = earnedScore
	if time > perfectTime and perfectTime > 0:
		var overTime = time - perfectTime
		var maxPenalty = 0.85
		var tau = perfectTime * 1.5
		var penaltyPercent = maxPenalty * (1.0 - exp(-overTime / tau))
		finalScore -= int(finalScore * penaltyPercent)
	finalScore = clamp(finalScore, 0, maxScore)
	var grade = _calcGrade(finalScore, maxScore)

	levelEnd._setScore(finalScore)
	levelEnd._setGrade(grade)
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
				particleInstance = shootingParticles.instantiate()
				particleInstance.position = gunParticleSpawn.global_position
				get_parent().add_child(particleInstance)
				particleInstance.emitting = true
	else:
		playerCam.position = Vector3();
		if animaPlayer.current_animation == "shootingAnim":
			animaPlayer.stop()
func _shoot():
	if currentGun == 0:
		playerCam.position = lerp(playerCam.position, Vector3(randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), 0), 0.5)
		if gunRay.is_colliding():
			var target = gunRay.get_collider()
			if target.has_method("_damage"):
				target._damage(damage)
			if target.has_method("_makeTarg"):
				target._makeTarg(self)
			var hit_pos = gunRay.get_collision_point()
			var hit_normal = gunRay.get_collision_normal()
			_spawn_bullet_hole(hit_pos, hit_normal)
			_draw_laser_line(gunParticleSpawn.global_position, gunRay.get_collision_point(), 0.25)
		else:
			var end_point = gunRay.to_global(gunRay.target_position)
			_draw_laser_line(gunParticleSpawn.global_position, end_point, 0.5)
	elif currentGun == 1:
		if !shotGunCd:
			playerCam.position = lerp(playerCam.position, Vector3(randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), 0), 0.5)
			shotGunCd = true
			shotGunCdTimer.start()
			rayContainer.randomizeRays()
			for ray in rayContainer.get_children():
				particleInstance = shootingParticles.instantiate()
				particleInstance.position = gunParticleSpawn.global_position
				get_parent().add_child(particleInstance)
				particleInstance.emitting = true
				if ray.is_colliding():
					var target = ray.get_collider()
					if target.has_method("_damage"):
						target._damage(shotGunDmg)
					if target.has_method("_makeTarg"):
						target._makeTarg(self)
					var hit_pos = ray.get_collision_point()
					var hit_normal = ray.get_collision_normal()
					_spawn_bullet_hole(hit_pos, hit_normal)
					_draw_laser_line(gunParticleSpawn.global_position, ray.get_collision_point(), 0.25)
				else:
					var end_point = ray.to_global(ray.target_position)
					_draw_laser_line(gunParticleSpawn.global_position, end_point, 0.5)
			_applyForce(shotgunForcePnt.global_position,10)


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

func _ready() -> void:
	maxScore = _calcMaxScore()
	print("maxScore: ", maxScore)
	finishOrb.open = true
	finishOrb.canvas =$levelEnd
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_footprint_tex = _make_teal_texture()
	_last_footprint_pos = global_position
	_bullet_tex = _make_bullet_texture()
	print("bullet tex: ", _bullet_tex)
	if _bullet_tex:
		print("bullet tex image: ", _bullet_tex.get_image())
	
	
func _process(delta: float) -> void:
	if count:
		time +=  delta
		timer.text = str(int(time))
	#call input functions
	_shootAnim()
	#NOTE-use only when unhandles input isnt good enough
	
func _unhandled_input(event: InputEvent) -> void:
	
	_switchGuns()
	#cam
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENS)
		playerCam.rotate_x(-event.relative.y * SENS)
		playerCam.rotation.x = clamp(playerCam.rotation.x,deg_to_rad(-90),deg_to_rad(90))
		
	if Input.is_action_just_pressed("jump"):
		jumpBuffer = JUMP_BUFFER_TIME

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
	
	if knockbackTimer > 0:
		knockbackTimer -= delta
	if dashCdTimer > 0:
		dashCdTimer -= delta
	if jumpBuffer > 0:
		jumpBuffer -= delta
	if wallJumpCd > 0:
		wallJumpCd -= delta
		
	if is_on_floor():
		coyoteTimer = COYOTE_TIME
		dashing = false
		upDashed = false
	elif coyoteTimer > 0:
		coyoteTimer -= delta
		
		
	if knockbackTimer <= 0:
		slide = Input.is_action_pressed("slide") and is_on_floor()
		if slide and not wasSliding:
			animaPlayer.play("slide")
			var currentDir = Vector3(velocity.x,0,velocity.z).normalized()
			if currentDir.length() > 0.1:
				velocity.x += currentDir.x * 6
				velocity.z += currentDir.z * 6
		wasSliding = slide
		if !slide:
			if animaPlayer.current_animation == "inSlide":
				animaPlayer.stop()
	
		if Input.is_action_just_pressed("dash") and dashCdTimer <= 0:
			animaPlayer.play("dash")
			var input_dir := Input.get_vector("left", "right", "forward", "backward")
			if input_dir.length() > 0.1:
				dashDir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			else:
				dashDir = -transform.basis.z
			dashCdTimer = dashCooldown
			var vericalNerf = 1
			if velocity.y != 0 and !upDashed:
					velocity.y = (Vector2(abs(velocity.x),abs(velocity.z)).length() / 2) * vericalNerf
					upDashed = true
			velocity.x = dashDir.x * dashBoost
			velocity.z = dashDir.z * dashBoost
			#since the y velocity will always be much smaller we can use velocity x and z to determine how much jump we need
			#and since we dont want spiderman here lets nerf it
		if is_on_floor():
			velocity += get_gravity()* delta;
	if knockbackTimer <= 0:
		if jumpBuffer > 0 and canWallJump and !is_on_floor() and wallJumpCd <= 0:
			var bounced = velocity.bounce(wallNormal)
			velocity.x = bounced.x * .4 + wallNormal.x *WALL_JUMP_BOOST
			velocity.z = bounced.z * .4 + wallNormal.z *WALL_JUMP_BOOST
			velocity.y = WALL_JUMP_VELOCITY
			wallJumpCd = WALL_JUMP_COOLDOWN
			jumpBuffer = 0
			upDashed = false
			
		if jumpBuffer > 0 and coyoteTimer > 0:
			coyoteTimer = 0.0
			jumpBuffer = 0.0
			velocity.y = JUMP_VELOCITY
		
	if not is_on_floor() and Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= 0.45
		
	if not is_on_floor():
		velocity += get_gravity() * delta
	if knockbackTimer <= 0:
		if not slide:
			if Input.is_action_just_pressed("jump") and coyoteTimer > 0:
				coyoteTimer = 0.0
				velocity.y = JUMP_VELOCITY

			var input_dir := Input.get_vector("left", "right", "forward", "backward")
			var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			var horizontal_speed = Vector2(velocity.x, velocity.z).length()

			if is_on_floor():
				if direction:
					var accel = 30.0 if horizontal_speed < SPEED else 10.0
					velocity.x = move_toward(velocity.x, direction.x * SPEED, accel * delta)
					velocity.z = move_toward(velocity.z, direction.z * SPEED, accel * delta)
				else:
					velocity.x = move_toward(velocity.x, 0, 28 * delta)
					velocity.z = move_toward(velocity.z, 0, 28 * delta)

			else:
				if direction:
					velocity.x += direction.x * airAccel * delta
					velocity.z += direction.z * airAccel * delta
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
				# Very low friction when sliding with no input — coast
				velocity.x = move_toward(velocity.x, 0, 2.0 * delta)
				velocity.z = move_toward(velocity.z, 0, 2.0 * delta)
	
	if is_on_floor():
		var flat_pos = Vector3(global_position.x, 0, global_position.z)
		var flat_last = Vector3(_last_footprint_pos.x, 0, _last_footprint_pos.z)
		if flat_pos.distance_to(flat_last) >= step_distance:
			var side = (_footprint_pool.size() % 2) * 2 - 1
			var perp = transform.basis.x * 0.15 * side
			_spawn_footprint(feet.global_position + perp)
			_last_footprint_pos = global_position

	move_and_slide()
	_checkWall()

func _updateHud():
	$HUD/ProgressBar.value = health

func _takeDamage(damage):
	health -= damage
	_updateHud()



#func here so i can jump here fast
func wallJump():pass

func _checkWall():
	if is_on_floor():
		canWallJump = false
		return
	
	if abs(velocity.x) + abs(velocity.y) > 1:
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
