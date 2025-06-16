extends Area2D


@export var damage = 750

@onready var aoe: CollisionShape2D = $AOE
@onready var explosion_radius: float = aoe.shape.radius


func _on_body_entered(body: Node2D) -> void:	
	if not body.is_in_group("enemy"):
		return
	
	if body.has_method("take_damage"):
		var distance = (
			body.global_position.distance_to(
				self.global_position
			)
		)
		var damage_factor = 1.0 - (distance / explosion_radius)
		var actual_damage = damage * damage_factor
		
		if actual_damage > 0:
			body.take_damage(actual_damage)
