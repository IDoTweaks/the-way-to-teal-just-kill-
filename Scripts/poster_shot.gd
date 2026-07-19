extends Node

var vp : SubViewport
var t := 0.0
var shot := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var w = int(OS.get_environment("POSTER_W"))
	var h = int(OS.get_environment("POSTER_H"))
	vp = SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var menu = load("res://Scenes/mainMenu.tscn").instantiate()
	vp.add_child(menu)
	var ui = menu.get_node_or_null("MainMenu2")
	if ui:
		ui.visible = false
		# CanvasLayers render independently of their parent Control's visibility
		for cl in ui.find_children("*", "CanvasLayer", true, false):
			cl.visible = false
	var sky = menu.get_node_or_null("Sky")
	if sky and sky.material:
		sky.material = sky.material.duplicate()
		sky.material.set_shader_parameter("frozenTime", float(OS.get_environment("POSTER_TIME")))


func _process(delta : float) -> void:
	t += delta
	if shot or t < 0.8:
		return
	shot = true
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(OS.get_environment("POSTER_OUT"))
	print("POSTER SAVED")
	get_tree().quit()
