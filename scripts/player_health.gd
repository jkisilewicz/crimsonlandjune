#player_health.gd

extends Label

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Wyświetlamy aktualne HP i maksymalne HP, rozdzielone " / "
		text = "Health: " + str(int(player.current_hp)) + " / " + str(int(player.stats["max_hp"]))
