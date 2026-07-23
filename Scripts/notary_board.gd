extends StaticBody3D

func _enemy():pass
func _notaryBoard():pass

func _root():
	var node = get_parent()
	while node != null and !node.has_method("_notary"):
		node = node.get_parent()
	return node

func _makeTarg(targ):
	var n = _root()
	if n != null:
		n._makeTarg(targ)

func _takeDamage(dmg):
	_damage(dmg)

func _damage(_dmg):
	var n = _root()
	if n != null:
		n._clink()
