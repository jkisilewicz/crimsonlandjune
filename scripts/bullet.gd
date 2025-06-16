class_name Bullet
extends Area2D

@export var speed = 3000
@export var damage = 24  # Changed default damage to 25
var is_critical = false  # Dodana zmienna dla trafień krytycznych

# Preload sceny z efektem krwi
@onready var blood_scene = preload("res://scenes/blood.tscn")

func _ready():
	# Jeśli pocisk jest krytyczny, zmień jego kolor na pomarańczowy od początku
	if is_critical:
		modulate = Color(1.0, 0.5, 0.0)  # Pomarańczowy kolor

func _physics_process(delta):
	position += Vector2(1, 0).rotated(rotation) * speed * delta

func set_damage(value):
	damage = value

func set_speed(value):
	speed = value

# Nowa funkcja do ustawiania pocisku jako krytyczny
func set_critical(value):
	is_critical = value
	
	if value:
		# Zmień kolor pocisku na pomarańczowy
		modulate = Color(1.0, 0.5, 0.0)  # Pomarańczowy kolor
		
		# Powiększ pocisk dla lepszej widoczności
		scale *= 1.5
		
		# Włącz efekt cząsteczkowy
		var particles = CPUParticles2D.new()
		particles.amount = 20
		particles.lifetime = 0.5
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
		particles.spread = 180
		particles.gravity = Vector2(0, 0)
		particles.initial_velocity_min = 50
		particles.initial_velocity_max = 70
		particles.color = Color(1.0, 0.5, 0.0)  # Pomarańczowy kolor
		particles.emitting = true  # Włącz emisję cząstek
		add_child(particles)

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
		
		# Jeśli był to trafienie krytyczne, dodaj specjalny efekt przy uderzeniu
		if is_critical:
			# Dodatkowy efekt eksplozji dla trafień krytycznych
			var crit_particles = CPUParticles2D.new()
			crit_particles.amount = 30
			crit_particles.lifetime = 0.7
			crit_particles.one_shot = true
			crit_particles.explosiveness = 0.8
			crit_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
			crit_particles.spread = 180
			crit_particles.gravity = Vector2(0, 0)
			crit_particles.initial_velocity_min = 100
			crit_particles.initial_velocity_max = 150
			crit_particles.color = Color(1.0, 0.5, 0.0)  # Pomarańczowy kolor
			crit_particles.emitting = true
			main_scene.add_child(crit_particles)
			crit_particles.global_position = global_position
			
			# Usuń cząsteczki po zakończeniu animacji
			var timer = Timer.new()
			timer.wait_time = 0.8
			timer.one_shot = true
			timer.autostart = true
			main_scene.add_child(timer)
			timer.timeout.connect(func(): crit_particles.queue_free())
			timer.timeout.connect(func(): timer.queue_free())
	
	queue_free()
