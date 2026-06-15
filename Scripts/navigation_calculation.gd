extends Node3D

@export var navObjects: Array[CharacterBody3D] = []
var tickAssigned = []
var tickCount = []
var currentTick = 0;
var tickTimer = 0.0
const TICK_RATE = 0.025

func _ready() -> void:
	tickAssigned.resize(navObjects.size())
	tickAssigned.fill(0)
	tickCount.resize(20);
	tickCount.fill(0)
	var length = navObjects.size()
	for i in tickAssigned.size():
		tickAssigned[i] = -1
	var num = 20.0 /length
	var current = 0.0
	for i in length:
		if current >= 20:
			current -= 20
		tickAssigned[i] = int(current)
		tickCount[int(current)]+=1
		current += num
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	tickTimer +=delta
	if tickTimer < TICK_RATE:
		return
	tickTimer = 0.0
	var tickDelta = TICK_RATE
	var count = 0
	for entity in navObjects:
		if entity != null:
			if tickAssigned[count] == currentTick:
				var target = entity.target
				if target != null:
					var navAgent = entity.navAgent
					var mode = entity.mode
					var gotShot = entity.gotShot
					var SPEED = entity.SPEED
					var accelaration = entity.accelaration
					var velocity = entity.velocity
					if mode == "chase" or gotShot:
						navAgent.target_position = Vector3(target.global_position.x,target.global_position.y,target.global_position.z)
						var dir = (navAgent.get_next_path_position() - entity.global_position).normalized()
						print(entity.name, navAgent.get_next_path_position())
						entity.velocity = velocity.lerp(dir * SPEED, tickDelta * accelaration)
						entity.look_at(Vector3(target.global_position.x,entity.global_position.y,target.global_position.z),Vector3.UP,true)
						entity.shouldMove = true
					elif mode == "attack":
						navAgent.target_position = Vector3(target.global_position.x,target.global_position.y,target.global_position.z)
						var dir = (navAgent.get_next_path_position() - entity.global_position).normalized()
						print(entity.name, navAgent.get_next_path_position())
						entity.velocity = velocity.lerp(dir * SPEED, tickDelta * accelaration)
						entity.look_at(Vector3(target.global_position.x,entity.global_position.y,target.global_position.z),Vector3.UP,true)
						entity.shouldMove = true
		count+=1
	currentTick +=1
	if currentTick >= 20:
		currentTick = 0
	

#@onready var body =$body
#@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
#var particleInstance
#@export var navAgent : NavigationAgent3D
#@export var damage = 10
#@export var accelaration = 10
#var target
#var mode : String = "idle"
#var gotShot = false
