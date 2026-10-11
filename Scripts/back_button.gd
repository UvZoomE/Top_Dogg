extends Button

func _pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
