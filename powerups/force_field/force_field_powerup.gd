extends Area2D


func _ready() -> void:
	Powerups.powerups_pool.erase("res://powerups/force_field/force_field_powerup.tscn")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.activate_force_field()
		queue_free()
