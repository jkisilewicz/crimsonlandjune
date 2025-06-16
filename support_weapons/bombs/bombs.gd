# bombs.gd
extends Area2D

@export var fall_speed = 200.0      # Prędkość spadania bomby
@export var explosion_radius = 500.0 # Promień eksplozji
@export var damage = 750             # Obrażenia zadawane przez bombę
@export var explosion_time = 0.1    # Czas do eksplozji po uderzeniu

# Załaduj teksturę eksplozji (zmień ścieżkę na właściwą)
@onready var explosion_texture = preload("res://images/enemies/enemy_bullet.png")
@onready var timer = $Timer
@onready var sfx_shoot = $sfx_shoot

func _ready():
	# Połącz sygnały
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Ustaw timer eksplozji
	timer.wait_time = explosion_time
	timer.one_shot = true
	timer.timeout.connect(_explode)

func _physics_process(delta):
	# Spadanie bomby
	position.y += fall_speed * delta
	
	# Jeśli bomba wypadła poza ekran, usuń ją
	if position.y > get_viewport_rect().size.y + 100:
		queue_free()

func _on_body_entered(_body):
	# Bomba uderzyła w coś - przygotuj eksplozję
	timer.start()
	# Zatrzymaj ruch bomby
	set_physics_process(false)

func _on_area_entered(_area):
	# Podobnie jak wyżej, ale dla obszarów
	timer.start()
	set_physics_process(false)

func _explode():
	# Stwórz efekt eksplozji ręcznie
	var explosion = Sprite2D.new()
	explosion.texture = explosion_texture
	explosion.z_index = 10 # Ustaw wysoki z_index, aby eksplozja była widoczna ponad innymi elementami
	
	# Dodaj eksplozję do sceny
	get_tree().get_current_scene().add_child(explosion)
	explosion.global_position = global_position
	
	# Animacja eksplozji
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
	tween.tween_property(explosion, "scale", Vector2.ONE * 2.0, 0.3).from(Vector2.ONE * 0.5)
	tween.tween_property(explosion, "modulate:a", 0.0, 0.2).set_delay(0.1)
	tween.chain().tween_callback(func(): explosion.queue_free())
	
# Odtwórz dźwięk eksplozji
	if has_node("sfx_shoot"):
		var sound = sfx_shoot
		# Odłącz dźwięk od bomby, aby dokończył odtwarzanie po zniszczeniu bomby
		remove_child(sound)
		get_tree().get_current_scene().add_child(sound)
		sound.global_position = global_position
		sound.play()
		
		# Stwórz timer, który usunie dźwięk po odtworzeniu
		var sound_timer = Timer.new()
		sound_timer.wait_time = 2.0  # Dostosuj do długości dźwięku
		sound_timer.one_shot = true
		sound_timer.timeout.connect(func(): sound.queue_free())
		sound.add_child(sound_timer)
		sound_timer.start()

	# Zadaj obrażenia wszystkim wrogom w zasięgu
	var enemies = get_tree().get_nodes_in_group("slime")
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			# Oblicz obrażenia z uwzględnieniem odległości
			var damage_factor = 1.0 - (distance / explosion_radius)
			var actual_damage = damage * damage_factor
			
			if enemy.has_method("take_damage"):
				enemy.take_damage(actual_damage)
	
	# Usuń bombę
	queue_free()
