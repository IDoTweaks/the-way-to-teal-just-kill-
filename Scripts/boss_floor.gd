extends Node3D
@onready var tile =$tileBody
@export var player : Node3D
@export var snake : Node3D
@export var width : int
@export var length : int
var floor = null
var removedTiles : Dictionary = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_genFloor(length,width,1.01)
	var selected = _selectRemoveable(100)
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
		selected = _selectRemoveable(width * length)
	else:
		selected = _selectRemoveable(toSelect)
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

func _selectRemoveable(ammount):
	if floor == null || floor.size() == 0 || floor[0].size() == 0:
		return []
	var cap = floor.size() * floor[0].size()
	if ammount > cap:
		ammount = cap
	var occupied = {}
	for p in snake._occupied():
		var c = _wrld2Tile(p.x,p.z)
		if c.x != -1:
			occupied[c] = true
	var pc = _wrld2Tile(player.global_position.x,player.global_position.z)
	if pc.x != -1:
		occupied[pc] = true
	var selected = []
	var attempts = 0
	while selected.size() < ammount and attempts < cap* 8:
		attempts +=1
		var i = randi_range(0,floor.size() - 1)
		var j = randi_range(0,floor[i].size() - 1)
		var tile = floor[i][j]
		if !is_instance_valid(tile) or removedTiles.has(tile) or selected.has(tile) or occupied.has(Vector2i(i,j)):
			continue
		var extra = {}
		for s in selected:
			extra[s] = true
		extra[tile] = true
		if !_stillConnected(selected + [tile]) or !_noDeadEnd(i,j,extra):
			continue
		selected.append(tile)
	for tile in selected:
		removedTiles[tile] = true
	return selected

func _stillConnected(removeArr):
	var removeSet = {}
	for tile in removeArr:
		removeSet[tile] = true
	var start = Vector2i(-1,-1)
	var tot =0
	for i in range(floor.size()):
		for j in range(floor[i].size()):
			var tile = floor[i][j]
			if !is_instance_valid(tile) or removedTiles.has(tile) or removeSet.has(tile):
				continue
			tot +=1
			if start.x == -1:
				start = Vector2i(i,j)
	if tot <= 1:
		return true
	var visited = {start : true}
	var queue = [start]
	var dirs = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
	var reached = 0
	while queue.size() > 0:
		var curr = queue.pop_front()
		reached+=1
		for dir in dirs:
			var nextX = curr.x + dir.x
			var nextZ = curr.y + dir.y
			if nextX < 0 or nextX >= floor.size() or nextZ < 0 or nextZ >= floor[nextX].size():
				continue
			var n = Vector2i(nextX,nextZ)
			if visited.has(n):
				continue
			var t = floor[nextX][nextZ]
			if !is_instance_valid(t) or removedTiles.has(t) or removeSet.has(t):
				continue
			visited[n] = true
			queue.append(n)
	return reached == tot
	

func _freeDeg(i,j,extra):
	var cnt = 0
	var dirs = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
	for dir in dirs:
		var nextI = i +dir.x
		var nextJ = j + dir.y
		if nextI < 0 or nextI >= floor.size() or nextJ < 0 or nextJ >= floor[nextI].size():
			continue
		var tile = floor[nextI][nextJ]
		if !is_instance_valid(tile) or removedTiles.has(tile) or extra.has(tile):
			continue
		cnt += 1
	return cnt

func _noDeadEnd(i,j,extra):
	var dirs = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
	for dir in dirs:
		var nextI = i +dir.x
		var nextJ = j + dir.y
		if nextI < 0 or nextI >= floor.size() or nextJ < 0 or nextJ >= floor[nextI].size():
			continue
		if _freeDeg(nextI,nextJ,extra) < 2:
			return false
	return true

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


func _pathFind(fromX,fromZ,toX,toZ,blockers = []):
	if floor == null:
		return floor #complicated way to return null XD
	var start = _wrld2Tile(fromX,fromZ)
	var goal = _wrld2Tile(toX,toZ)
	if start.x == -1 || goal.x == -1: return null
	if start == goal:return floor[start.x][start.y]
	var blocked = {}
	for b in blockers:
		var tmp = _wrld2Tile(b.x,b.z)
		if tmp.x != -1:
			blocked[tmp] = true
	var visited = {start: true}
	var cameFrom = {}
	var queue = [start]
	var dirs = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
	var found = false
	var best = start
	var bestDist = INF
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
			if blocked.has(n) and n!=goal:
				continue
			if !is_instance_valid(floor[nextX][nextZ]):
				continue
			visited[n] = true
			cameFrom[n] = curr
			queue.append(n)
			var hd = abs(n.x - goal.x) + abs(n.y -goal.y)
			if hd < bestDist:
				bestDist = hd
				best = n
	var dest = goal if found else best
	if dest == start:
		return null
	var step = goal
	while cameFrom.has(step) and cameFrom[step] != start:
		step = cameFrom[step]
	return floor[step.x][step.y]
