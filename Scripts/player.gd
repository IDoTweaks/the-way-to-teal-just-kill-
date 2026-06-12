extends CharacterBody3D

const SENS = 0.005;
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAXCAMSHAKE = 0.03

#sliding
var slide :bool = false
@export var downForceDevide: float
@export var slideFactor: float = 0.4
@export var slideDownforce: float = 20.0

@onready var feet = $feetPos;
@onready var playerCam = $playerCam;
@onready var animaPlayer = $AnimationPlayer
@onready var gunRay = $playerCam/RayCast3D
@onready var shootingParticles =preload("res://Particles/shootParticles.tscn")
@onready var gunParticleSpawn = $playerCam/gun/particleSpawnGun
var particleInstance

#gun
@export var damage : float = 10
func _shootAnim():
	if Input.is_action_pressed("shoot"):
		animaPlayer.play("shootingAnim")
		particleInstance = shootingParticles.instantiate()
		particleInstance.position = gunParticleSpawn.global_position
		get_parent().add_child(particleInstance)
		particleInstance.emitting = true
	else:
		playerCam.position = Vector3();
		animaPlayer.stop()
func _shoot():
	playerCam.position = lerp(playerCam.position, Vector3(randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), randf_range(MAXCAMSHAKE, -MAXCAMSHAKE), 0), 0.5)
	
	if gunRay.is_colliding():
		var target = gunRay.get_collider()
		if target.has_method("enemy"):
			target.health -= damage
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
	if Input.is_action_pressed("slide"):
		slide = true
	else:
		slide = false
	if !is_on_floor():
		slide = false
	
	if not slide:
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		var force = _calcDownForce()
		
		var slideMod = clamp(slideFactor + (force / downForceDevide),0,2.5)
			# Add the gravity.
		
		#DO NOT REMOVE -- if making any changes to sliding this is the most important part  which keeps us from  flying
		if force > 0:
			velocity.y = -force * slideDownforce

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var slide_accel = 5
		
		if direction:
			var targetXVel = direction.x * SPEED * slideMod
			var targetZVel = direction.z * SPEED * slideMod
			velocity.x = lerp(velocity.x, targetXVel, slide_accel * delta)
			velocity.z = lerp(velocity.z, targetZVel, slide_accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * slideMod * delta * slide_accel)
			velocity.z = move_toward(velocity.z, 0, SPEED * slideMod* delta * slide_accel)

	move_and_slide()
