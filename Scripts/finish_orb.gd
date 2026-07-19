extends Node3D
@export var toLevel: int
@export var tutorialExit: bool = false
@export var killLock: bool = true
var canvas
var open = false
var locked = false
var lockMat : ShaderMaterial
var lockLabel : Label3D
var pollAccum : float = 0.0
var baseScale : Vector3
@export var player: CharacterBody3D
@onready var orbMesh = $MeshInstance3D

const LOCK_CORE = Color(0.05, 0.09, 0.08)
const LOCK_MID = Color(0.14, 0.22, 0.19)
const LOCK_RIM = Color(0.3, 0.42, 0.38)
const OPEN_CORE = Color(0.03, 0.18, 0.13)
const OPEN_MID = Color(0.11, 0.62, 0.46)
const OPEN_RIM = Color(0.3, 1, 0.75)

func _ready() -> void:
	baseScale = scale
	if killLock:
		if _enemiesLeft() <= 0:
			killLock = false
			return
		lockMat = orbMesh.mesh.surface_get_material(0).duplicate()
		orbMesh.material_override = lockMat
		_buildLockLabel()
		_setLocked(true)

func _buildLockLabel():
	lockLabel = Label3D.new()
	lockLabel.font = load("res://Fonts/LilitaOne.tres")
	lockLabel.font_size = 64
	lockLabel.outline_size = 20
	lockLabel.modulate = Color(1.0, 0.99, 0.94)
	lockLabel.outline_modulate = Color(0.031, 0.133, 0.149)
	lockLabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lockLabel.no_depth_test = true
	lockLabel.pixel_size = 0.012
	add_child(lockLabel)
	lockLabel.position = Vector3(0, 1.6, 0)

func _enemiesLeft() -> int:
	var n = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("dead") != true:
			n += 1
	return n

func _setLocked(v : bool):
	locked = v
	if lockMat == null:
		return
	if locked:
		lockMat.set_shader_parameter("core_color", LOCK_CORE)
		lockMat.set_shader_parameter("mid_color", LOCK_MID)
		lockMat.set_shader_parameter("rim_color", LOCK_RIM)
		lockMat.set_shader_parameter("swirl_speed", 0.12)
		lockMat.set_shader_parameter("pulse_strength", 0.05)
		scale = baseScale * 0.75
	else:
		var tw = create_tween()
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_ELASTIC)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", baseScale, 0.7)
		tw.tween_method(_lerpOrbColors, 0.0, 1.0, 0.5)
		lockMat.set_shader_parameter("swirl_speed", 0.6)
		lockMat.set_shader_parameter("pulse_strength", 0.25)
		if lockLabel:
			lockLabel.text = ""
		Audio.play("win", 1.5, -8.0)

func _lerpOrbColors(t : float):
	lockMat.set_shader_parameter("core_color", LOCK_CORE.lerp(OPEN_CORE, t))
	lockMat.set_shader_parameter("mid_color", LOCK_MID.lerp(OPEN_MID, t))
	lockMat.set_shader_parameter("rim_color", LOCK_RIM.lerp(OPEN_RIM, t))

func _process(delta: float) -> void:
	if !killLock or !locked:
		return
	pollAccum += delta
	if pollAccum < 0.2:
		return
	pollAccum = 0.0
	var left = _enemiesLeft()
	if left <= 0:
		_setLocked(false)
	elif lockLabel:
		lockLabel.text = str(left) + " LEFT"

func _on_finish_area_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		if locked:
			_lockedBonk()
			return
		if open:
			open = false
			if tutorialExit:
				Global._finishTutorial()
			else:
				player._finishLevel()

func _lockedBonk():
	Audio.play("boing", 0.7, -8.0)
	if lockLabel:
		var tw = create_tween()
		tw.set_trans(Tween.TRANS_ELASTIC)
		tw.set_ease(Tween.EASE_OUT)
		lockLabel.scale = Vector3.ONE * 1.8
		tw.tween_property(lockLabel, "scale", Vector3.ONE, 0.45)

func _finishLevel():
	var level = Global.levels[toLevel]
	get_tree().change_scene_to_packed(level)
