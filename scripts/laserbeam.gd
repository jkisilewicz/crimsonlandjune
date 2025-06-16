#laserbeam.gd
extends Area2D

@export var speed = 3000
@export var damage = 24  # Changed default damage to 25
var lifetime = 0.5

# Preload sceny z efektem krwi
@onready var blood_scene = preload("res://scenes/blood.tscn")


func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func set_damage(value):
	damage = value

func _on_body_entered(body):
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
		
		$CollisionShape2D.disabled = true
	#queue_free()
