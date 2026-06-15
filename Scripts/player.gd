extends CharacterBody3D
func player():pass
const SENS = 0.005;
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAXCAMSHAKE = 0.03
@export var health = 100

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
var particleInstance

#general movement
var airAccel = 8
var coyoteTimer: float = 0
const COYOTE_TIME = 0.12
var jumpBuffer: float = 0
const JUMP_BUFFER_TIME = 0.12
var upDashed = false;


#footprint system
@export var step_distance: float = 0.5
@export var decal_size: float = 0.4
@export var max_footprints: int = 60

var _last_footprint_pos: Vector3 = Vector3.ZERO
var _footprint_pool: Array[Node] = []
var _footprint_tex: ImageTexture

func _make_teal_texture() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	for x in range(64):
		for y in range(64):
			var d = Vector2(x, y).distance_to(center)
			if d < 30:
				var alpha = clamp(1.0 - (d / 30) * 0.3, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.11, 0.62, 0.46, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex

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
@export var max_bullet_holes: int = 40

var _bullet_pool: Array[Node] = []
var _bullet_tex: ImageTexture

func _make_bullet_texture() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	for x in range(64):
		for y in range(64):
			var d = Vector2(x, y).distance_to(center)
			if d < 10:
				img.set_pixel(x, y, Color(0.02, 0.05, 0.15, 1))
			elif d < 18:
				var t = (d - 10) / 8.0
				img.set_pixel(x, y, Color(0.15, 0.65, 1, 1 - t * 0.3))
			elif d < 28.0:
				var t = (d - 18) / 10
				img.set_pixel(x, y, Color(0.1, 0.4, 0.8, (1 - t) * 0.6))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex

func _spawn_bullet_hole(pos: Vector3, normal: Vector3) -> void:
	var decal = Decal.new()
	decal.size = Vector3(bullet_hole_size, 1.0, bullet_hole_size)
	decal.texture_albedo = _bullet_tex
	decal.albedo_mix = 1.0
	decal.modulate = Color(0.11,.62,.4,1)
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

func _startInSlide():
	animaPlayer.play("inSlide")

func _shootAnim():
	if Input.is_action_pressed("shoot"):
		animaPlayer.play("shootingAnim")
		particleInstance = shootingParticles.instantiate()
		particleInstance.position = gunParticleSpawn.global_position
		get_parent().add_child(particleInstance)
		particleInstance.emitting = true
	else:
		playerCam.position = Vector3();
		if animaPlayer.current_animation == "shootingAnim":
			animaPlayer.stop()
func _shoot():
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
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	_footprint_tex = _make_teal_texture()
	_last_footprint_pos = global_position
	_bullet_tex = _make_bullet_texture()
	
	
func _process(delta: float) -> void:
	#call input functions
	_shootAnim()
	#NOTE-use only when unhandles input isnt good enough
	
func _unhandled_input(event: InputEvent) -> void:
	#cam
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENS)
		playerCam.rotate_x(-event.relative.y * SENS)
		playerCam.rotation.x = clamp(playerCam.rotation.x,deg_to_rad(-60),deg_to_rad(70))
		
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
	if dashCdTimer > 0:
		dashCdTimer -= delta
	if jumpBuffer > 0:
		jumpBuffer -= delta
		
	if is_on_floor():
		coyoteTimer = COYOTE_TIME
		dashing = false
	elif coyoteTimer > 0:
		coyoteTimer -= delta
		
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
		velocity.x = dashDir.x * dashBoost
		velocity.z = dashDir.z * dashBoost
		#since the y velocity will always be much smaller we can use velocity x and z to determine how much jump we need
		#and since we dont want spiderman here lets nerf it
		var vericalNerf = .05
		if !is_on_floor() and !upDashed:
				velocity.y = ((Vector2(velocity.x,velocity.z).length() / 2) * dashBoost) * vericalNerf
				upDashed = true
		if is_on_floor():
			upDashed = false
			velocity += get_gravity()* delta;
		
	if jumpBuffer > 0 and coyoteTimer > 0:
		coyoteTimer = 0.0
		jumpBuffer = 0.0
		velocity.y = JUMP_VELOCITY
		
	if not is_on_floor() and Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= 0.45
		
	if not is_on_floor():
		velocity += get_gravity() * delta
		
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



func _takeDamage(damage):
	health -= damage
	print("taken", damage)
