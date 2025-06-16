#player_level.gd
extends Label

func update_level(new_level_value: int) -> void:
	text = "Level: " + str(new_level_value)
