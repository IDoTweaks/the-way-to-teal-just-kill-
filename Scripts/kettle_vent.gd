extends StaticBody3D

func _enemy():pass
func _kettleVent():pass

@export var dmgMult : float = 2.0

func _root():
	var node = get_parent()
	while node != null and !node.has_method("_kettle"):
		node = node.get_parent()
	return node

func _makeTarg(targ):
	var kettle = _root()
	if kettle != null:
		kettle._makeTarg(targ)

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	var kettle = _root()
	if kettle != null:
		kettle._ventDamage(dmg * dmgMult)
