class_name ExplosiveBullet
extends Area2D

@export var speed = 1000
@export var explosion_radius = 500.0 # Promień eksplozji
@export var damage = 24  # Changed default damage to 25

# Preload sceny z efektem krwi
@onready var blood_scene = preload("res://scenes/blood.tscn")


func _physics_process(delta):
	position += Vector2(1, 0).rotated(rotation) * speed * delta

func set_damage(value):
	damage = value

func set_speed(value: float):
	speed = value

func set_explosion_radius(value: float):
	explosion_radius = value

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	var enemies = get_tree().get_nodes_in_group("slime")
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			# Oblicz obrażenia z uwzględnieniem odległości
			var damage_factor = 1.0 - (distance / explosion_radius)
			var actual_damage = damage * damage_factor
			
			if enemy.has_method("take_damage"):
				enemy.take_damage(actual_damage)
		
	queue_free()
