# turret_bullet_bullet.gd
extends Area2D

@export var speed = 600.0
@export var damage = 15.0
@export var lifetime = 2.0  # Czas życia pocisku w sekundach

func _ready():
	# Utwórz timer do automatycznego usunięcia pocisku
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	
	# Połącz sygnał body_entered
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Ruch pocisku do przodu
	position += Vector2(1, 0).rotated(rotation) * speed * delta

func set_damage(value):
	damage = value

func _on_body_entered(body):
	if body.is_in_group("slime") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
