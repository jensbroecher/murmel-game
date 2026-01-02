extends Node

var collected_diamond_ids: Array = []
var lives: int = 7

func register_collected(diamond_id: String):
	if not collected_diamond_ids.has(diamond_id):
		collected_diamond_ids.append(diamond_id)

func is_collected(diamond_id: String) -> bool:
	return collected_diamond_ids.has(diamond_id)

func clear_collected():
	collected_diamond_ids.clear()

func reset_lives():
	lives = 7

func lose_life() -> bool:
	lives -= 1
	return lives > 0
