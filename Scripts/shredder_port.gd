extends StaticBody3D
func _enemy(): pass
func _shredderPort(): pass

@export var dmgMult : float = 2.0

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	var shredder = get_parent()
	if shredder and shredder.has_method("_portDamage"):
		shredder._portDamage(dmg * dmgMult)

func _makeTarg(targ):
	var shredder = get_parent()
	if shredder and shredder.has_method("_makeTarg"):
		shredder._makeTarg(targ)
