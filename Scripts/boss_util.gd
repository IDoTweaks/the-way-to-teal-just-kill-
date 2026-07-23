extends Node
func _bossUtil(): pass

static func spawnParticleAt(host : Node3D, scene, pos : Vector3):
	var p = scene.instantiate()
	host.get_parent().add_child(p)
	p.global_position = pos
	p.emitting = true
	return p

static func spawnDmgTxt(host : Node3D, scene, at : Vector3, dmg : int):
	var txt = scene.instantiate()
	host.get_parent().add_child(txt)
	txt.global_position = at
	txt.damage = dmg
	return txt

static func lobVelocity(from : Vector3, to : Vector3, t : float) -> Vector3:
	var g = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var d = to - from
	var v = Vector3.ZERO
	v.x = d.x / t
	v.z = d.z / t
	v.y = (d.y + .5 * g * t * t) / t
	return v

static func floorPoint(host : Node3D, from : Vector3, skip : Array[RID], up : float = 3.0, down : float = 8.0):
	var space = host.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from + Vector3(0, up, 0), from + Vector3(0, -down, 0))
	ray.exclude = skip
	var hit = space.intersect_ray(ray)
	if hit:
		return hit.position + Vector3(0, .05, 0)
	return null

static func windowDamage(boss, dmg : float) -> float:
	var cap = boss.maxHealth * boss.stageDamage
	var left = cap - boss.stageDmg
	if left <= 0:
		return 0.0
	dmg = min(dmg, cap * boss.maxHit)
	dmg = min(dmg, left)
	boss.stageDmg += dmg
	return dmg
