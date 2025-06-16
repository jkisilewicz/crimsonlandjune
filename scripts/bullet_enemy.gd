extends Area2D

var direction = Vector2.ZERO
var speed = 300
var damage = 10
var rotation_speed = 10.0  # Prędkość rotacji w radianach na sekundę

func _ready():
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)
	
	# Set bullet to automatically delete itself after 5 seconds
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(queue_free)

func _physics_process(delta):
	# Manually update position
	position += direction * speed * delta
	
	# Obracaj kulę w czasie lotu
	rotation += rotation_speed * delta

func set_direction(dir: Vector2):
	direction = dir.normalized()

func _on_body_entered(body):
	if body.name == "Player" and body.has_method("apply_damage"):
		body.apply_damage(damage)
		queue_free()
