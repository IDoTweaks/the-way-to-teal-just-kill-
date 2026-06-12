extends CharacterBody3D

const  sens = 0.005;
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var slide :bool = false
@export var downForceDevide: float
@export var slideFactor: float = 0.4
@export var slideDownforce: float = 20.0

@onready var feet = $feetPos;
@onready var playerCam = $playerCam;

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sens)
		playerCam.rotate_x(-event.relative.y * sens)
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
