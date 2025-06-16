extends Area2D


@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var drone_cluster: Node2D = $DroneCluster


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	set_collision_mask_value(1, false)
	
	sprite_2d.hide()
	
	# Reset position and add as player's child
	position = Vector2.ZERO
	get_parent().remove_child(self)
	body.add_child(self)
	
	
	drone_cluster.is_active = true
	drone_cluster.show()
