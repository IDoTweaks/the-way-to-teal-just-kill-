extends StaticBody3D

func _enemy(): pass
func _snakePart(): pass

@export var dmgMult : float = 1.0

func _root():
	var node = get_parent()
	while node != null and !node.has_method("_snake"):
		node = node.get_parent()
	return node

func _makeTarg(targ):
	var snake = _root()
	if snake != null:
		snake._makeTarg(targ)

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	var snake = _root()
	if snake != null:
		snake._damage(dmg * dmgMult)
