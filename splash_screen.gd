extends Control

func _ready():
	# Simple 2-second delay with a black screen or logo if we had one
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://main_menu.tscn")
