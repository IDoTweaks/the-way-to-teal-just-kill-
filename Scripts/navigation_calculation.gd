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
	if length == 0:
		return
	var num = 20.0 /length
	var current = 0.0
	for i in length:
		if current >= 20:
			current -= 20
		tickAssigned[i] = int(current)
		tickCount[int(current)]+=1
		current += num


func _process(delta: float) -> void:
	tickTimer += delta
	if tickTimer < TICK_RATE:
		return
	tickTimer = 0.0
	var tickDelta = TICK_RATE
	var count = 0
	for entity in navObjects:
		if entity != null and is_instance_valid(entity) and entity.has_method("_enemy") and not entity.has_method("_selfDriven"):
			if count < tickAssigned.size() and tickAssigned[count] == currentTick:
				var navAgent = entity.get("navAgent")
				var target = entity.get("target")
				if navAgent != null and target != null and is_instance_valid(target) and entity.mode == "chase":
					navAgent.target_position = target.global_position
					var dir = (navAgent.get_next_path_position() - entity.global_position).normalized()
					entity.velocity = entity.velocity.lerp(dir * entity.SPEED, tickDelta * entity.accelaration)
					entity.shouldMove = true
		count += 1
	currentTick += 1
	if currentTick >= 20:
		currentTick = 0
