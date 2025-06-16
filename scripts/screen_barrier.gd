extends StaticBody2D


var player


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	# Formula: mapped_value = 0.3 + (1 - 0.3) * (x - 1) / (50 - 1)
	var mapped_value = 0.3 + (0.7 * (player.level - 1)) / 49
	
	var scale_tween = get_tree().create_tween()
	
	scale_tween.tween_property(
			self,
			"scale",
			Vector2(mapped_value, mapped_value),
			2
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
