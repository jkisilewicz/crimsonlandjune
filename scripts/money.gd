#bullet_fire.gd
extends Area2D

@export var speed = 3000
@export var damage = 24  # Changed default damage to 25
@export var delete_after := 1.5
@export var min_speed := 100

# Preload sceny z efektem krwi
@onready var blood_scene = preload("res://scenes/blood.tscn")

var slow_down: bool = false
var slow_down_rate: Array[float] = [1, 2]


func _physics_process(delta):
	if slow_down and speed > 0:
		# Slow down bullet over time
		var speed_tween = create_tween()
		speed_tween.tween_property(
				self,
				"speed",
				min_speed,
				randf_range(slow_down_rate[0], slow_down_rate[1])
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		
		speed_tween.connect("finished", _disable_collision)
		
		# Delete bullet after "delete_after" seconds
		var fade_tween = get_tree().create_tween()
		fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, delete_after).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		
		fade_tween.finished.connect(queue_free)
		
	position += Vector2(1, 0).rotated(rotation) * speed * delta

func _disable_collision():
	$CollisionShape2D.set_deferred("disabled", true)

func set_speed(value: float):
	speed = value

func set_slow_down_rate(value: Array[float]):
	slow_down = true
	slow_down_rate = value

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
		
		_disable_collision()
