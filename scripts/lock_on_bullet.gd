class_name LockOnBullet
extends Area2D

@export var speed = 1000
## Rotation speed value in deg/sec
@export var rotation_speed = 5
@export var explosion_radius = 500.0 # Promień eksplozji
@export var damage = 24  # Changed default damage to 25

# Preload sceny z efektem krwi
@onready var blood_scene = preload("res://scenes/blood.tscn")

var original_speed 

var targets = []
var target: Node2D


func _ready() -> void:
	original_speed = speed
	speed *= 3


func _physics_process(delta):
	speed = lerpf(speed, original_speed, 4 * delta)
	
	position += Vector2(1, 0).rotated(rotation) * speed * delta
	
	if is_instance_valid(target):
		var direction_to_target = (
				global_position.direction_to(target.global_position).normalized()
		)
		var rotation_target = atan2(direction_to_target.y, direction_to_target.x)
		
		rotation = lerp_angle(rotation, rotation_target, rotation_speed * delta)
	else:
		if targets.is_empty():
			return
		# This variable will record of the closest target distance
		var min_distance = INF
		for _target in targets:
			var distance = self.global_position.distance_to(_target.global_position)
			if distance < min_distance:
				min_distance = distance
				target = _target

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


func _on_search_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemy"):
		return
	
	targets.append(body)


func _on_search_area_body_exited(body: Node2D) -> void:
	if body in targets:
		targets.erase(body)
