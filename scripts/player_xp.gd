#player_xp.gd

extends Label

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		text = str(player.xp)
