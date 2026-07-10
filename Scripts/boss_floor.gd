extends Node3D
@onready var tile =$tileBody
@export var player : Node3D
@export var snake : Node3D
@export var width : int
@export var length : int
var floor = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_genFloor(length,width,1.01)
	var selected = _randSelectTiles(100)
	for i in selected:
		i._activate(0)
	

func _selectAndShoot(toSelect : int):
	var selected
	if toSelect > width * length:
		selected = _randSelectTiles(width * length)
	else:
		selected = _randSelectTiles(toSelect)
	for i in selected:
		i._activate(1)

func _selectAndRemove(toSelect : int):
	var selected
	if toSelect > width * length:
		selected = _randSelectTiles(width * length)
	else:
		selected = _randSelectTiles(toSelect)
	for i in selected:
		i._activate(0)

func _genFloor(height : int, width : int,dist):
	var arr = []
	for i in range(0,width):
		arr.append([])
		for j in range(0,height):
			var temp = tile.duplicate()
			self.add_child(temp)
			#temp.create_convex_collision()
			arr[i].append(temp)
	_arangeFloor(dist,arr,tile.position.x,tile.position.z)
	floor = arr
	tile.queue_free()

func _arangeFloor(dist,arr : Array, baseX,baseZ):
	var horiz = 0;
	var vert = 0;
	for i in range(0,arr.size()):
		vert = 0
		for j in range(0,arr[i].size()):
			arr[i][j].position.x = baseX + (horiz * dist)
			arr[i][j].position.z = baseZ + (vert * dist)
			if i == arr.size() / 2 and j == arr[i].size() / 2:
				player.global_position.x = arr[i][j].global_position.x
				player.global_position.z = arr[i][j].global_position.z
				snake.global_position.x = arr[i][j].global_position.x
				snake.global_position.z = arr[i][j].global_position.z
			vert+=1;
		horiz+=1

func _randSelectTiles(ammount : int):
	var count : int = 0;
	var selected : Array = []
	while count < ammount:
		for i in range(0,floor.size()):
			for j in range(0,floor.size()):
				if randi_range(1,250) == 5 and !selected.has(floor[i][j]):
					selected.append(floor[i][j])
					count+=1;
				if count >= ammount:
					return selected
	return selected

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _wrld2Tile(x,z):
	var best = Vector2i(-1,-1)
	var bestDist = INF
	for i in range(floor.size()):
		for j in range(floor[i].size()):
			var tile = floor[i][j];
			if!is_instance_valid(tile):
				continue
			var distX = tile.global_position.x - x
			var distZ = tile.global_position.z - z
			var dist = (distX * distX) + (distZ * distZ)
			if dist < bestDist:
				bestDist = dist
				best = Vector2i(i,j)
	return best


func _pathFind(fromX,fromZ,toX,toZ):
	if floor == null:
		return floor #complicated way to return null XD
	var start = _wrld2Tile(fromX,fromZ)
	var goal = _wrld2Tile(toX,toZ)
	if start.x == -1 || goal.x == -1: return null
	if start == goal:return floor[start.x][start.y]
	var visited = {start: true}
	var cameFrom = {}
	var queue = [start]
	var dirs = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
	var found = false
	while queue.size() > 0:
		var curr = queue.pop_front()
		if curr == goal:
			found = true
			break
		else:
			pass
		for d in dirs:
			var nextX = curr.x + d.x
			var nextZ = curr.y + d.y
			if nextX < 0 or nextX >= floor.size():
				continue
			if nextZ < 0 or nextZ >= floor.size():
				continue
			var n = Vector2i(nextX,nextZ)
			if visited.has(n):
				continue
			if !is_instance_valid(floor[nextX][nextZ]):
				continue
			visited[n] = true
			cameFrom[n] = curr
			queue.append(n)
	if !found:
		return null
	var step = goal
	while cameFrom.has(step) and cameFrom[step] != start:
		step = cameFrom[step]
	return floor[step.x][step.y]
