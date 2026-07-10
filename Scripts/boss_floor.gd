extends Node3D
@onready var tile =$tileBody
@onready var player = $Player2
@onready var snake = $Snake
@export var width : int
@export var length : int
var floor
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
