extends Node3D
@onready var tile =$tileBody/baseTile

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_genFloor(10,10,1.01)

func _genFloor(height : int, width : int,dist):
	var arr = []
	for i in range(0,width):
		arr.append([])
		for j in range(0,height):
			var temp = tile.duplicate()
			self.add_child(temp)
			temp.create_convex_collision()
			arr[i].append(temp)
	_arangeFloor(dist,arr,tile.position.x,tile.position.z)

func _arangeFloor(dist,arr : Array, baseX,baseZ):
	var horiz = 0;
	var vert = 0;
	for i in range(0,arr.size()):
		vert = 0
		for j in range(0,arr[i].size()):
			arr[i][j].position.x = baseX + (horiz * dist)
			arr[i][j].position.z = baseZ + (vert * dist)
			vert+=1;
		horiz+=1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
