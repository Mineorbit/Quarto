extends Control

const MAINMENU_UID = "uid://d3m6it0f8umm7"


func on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAINMENU_UID)
