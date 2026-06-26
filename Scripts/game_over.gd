extends CanvasLayer

#func _on_quit_btn_button_down() -> void:
#	get_tree().quit(6967)



#func _on_retry_button_down() -> void:
#	get_tree().change_scene_to_packed(Global.levels[1])


func _on_retry_button_down() -> void:
	Global._goToLevel(Global.currentLevel)


func _on_quit_btn_button_down() -> void:
	get_tree().quit(6967)
