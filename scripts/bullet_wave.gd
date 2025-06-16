class_name BulletWave
extends Area2D

@export var speed = 1000
@export var damage = 25  # Changed default damage to 25

var knock_back_strength = 10

# Preload sceny z efektem krwi
@onready var blood_scene = preload("res://scenes/blood.tscn")


func _physics_process(delta):
	position += Vector2(1, 0).rotated(rotation) * speed * delta
	
	# Scale wave bigger over time
	var scale_tween = create_tween()
	scale_tween.tween_property(
			self,
			"scale",
			Vector2(5, 5),
			2
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	get_tree().create_timer(10).timeout.connect(queue_free)


func set_knock_back_strength(value: float):
	knock_back_strength = value

func set_damage(value):
	damage = value

func set_speed(value):
	speed = value


func _on_body_entered(body: Node2D):
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
		
		if body.has_method("knock_back"):
			body.knock_back(knock_back_strength)
		
		# Reduce damage every hit
		damage *= 0.7
