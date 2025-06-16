class_name ElectricBullet
extends Area2D

@export var speed = 3000
@export var damage = 24  # Changed default damage to 25

# Preload sceny z efektem krwi
@onready var blood_scene = preload("res://scenes/blood.tscn")

@onready var extra_damage_collision: CollisionShape2D = $ExtraDamageArea/CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D

var hit_pos
var bodies_inside = []


func _physics_process(delta):
	position += Vector2(1, 0).rotated(rotation) * speed * delta

func set_damage(value):
	damage = value

func set_speed(value):
	speed = value


func _on_body_entered(body):
	if body in bodies_inside:
		bodies_inside.erase(body)
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
		# Spawn blood effect at collision point
		var blood_effect = blood_scene.instantiate()
		
		# Dodajemy do głównej sceny gry aby krew pozostała nawet po zniszczeniu przeciwnika
		var main_scene = get_tree().get_current_scene()
		main_scene.add_child(blood_effect)
		
		# Pozycja i inicjalizacja efektu krwi
		blood_effect.global_position = global_position
		blood_effect.initialize(rotation)
		
		# Hide sprite after hitting the enemy, waiting for the extra damage
		sprite_2d.visible = false
		
		if bodies_inside.is_empty():
			queue_free()
		else:
			# Stop bullet for extra damage
			speed = 0
			_deal_extra_damage()


func _deal_extra_damage() -> void:
	var target_enemy = bodies_inside.pick_random()
	
	if target_enemy == null:
		return
	
	if target_enemy.has_method("take_damage"):
		target_enemy.take_damage(damage)
		
		var zap_line = Line2D.new()
		zap_line.add_point(Vector2.ZERO, 0)
		zap_line.add_point(to_local(target_enemy.global_position), 1)
		zap_line.width = 30
		zap_line.default_color = Color.SKY_BLUE
		add_child(zap_line)
	
	await get_tree().create_timer(0.2).timeout
	queue_free()


func _add_bodies_inside(body: Node2D) -> void:
	if body in bodies_inside:
		return
	
	bodies_inside.append(body)
