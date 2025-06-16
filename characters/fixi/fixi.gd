#fixi.gd
extends CharacterBody2D

signal died

@onready var player: CharacterBody2D = $"../Player"
@onready var damage_timer: Timer = $DamageTimer
@onready var hit_area: Area2D = $HitArea
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hurt_timer: Timer = $HurtTimer
@onready var sprite = %RoundEnemyBody
@onready var shooting_area: Area2D = %ShootingArea  # Changed from charge_area to shooting_area
@onready var shoot_timer: Timer = $ShootTimer  # New timer for shooting

var health: int = 100
const DAMAGE_RATE = 4.0
const EXPERIENCE_REWARD = 50
var is_hurt = false

# Zmienna do przechowywania aktualnego celu
var current_target = null

# -- Zmienne do wędrowania:
var normal_speed = 200.0
var is_wandering = false
var wander_direction = Vector2.ZERO  # kierunek wędrowania
var is_shooting = false  # czy wróg jest w trybie strzelania

func _ready():
	# Dodaj do grupy enemy, aby drony mogły go wykrywać
	add_to_group("enemy")
	
	# Utworzenie Timer'a programowo jeśli nie został dodany w edytorze
	if not has_node("HurtTimer"):
		hurt_timer = Timer.new()
		hurt_timer.name = "HurtTimer"
		hurt_timer.one_shot = true
		hurt_timer.wait_time = 0.5  # Dostosuj do długości animacji hurt
		add_child(hurt_timer)
	
	# Utworzenie Timer'a do strzelania
	if not has_node("ShootTimer"):
		shoot_timer = Timer.new()
		shoot_timer.name = "ShootTimer"
		shoot_timer.one_shot = false
		shoot_timer.wait_time = 3.0  # Jeden pocisk co 3 sekundy
		add_child(shoot_timer)
	
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	play_walk()
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	hit_area.body_exited.connect(_on_hit_area_body_exited)
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	
	# Podłączamy sygnały do obsługi strzelania:
	shooting_area.body_entered.connect(_on_shooting_area_body_entered)
	shooting_area.body_exited.connect(_on_shooting_area_body_exited)

func _physics_process(_delta):
	# Znajdź najbliższy cel (gracz lub przyjaciel)
	var target = player
	var alliance = get_tree().get_nodes_in_group("alliance")
	
	if alliance.size() > 0:
		var player_distance = global_position.distance_to(player.global_position)
		for ally in alliance:
			if is_instance_valid(ally):
				var ally_distance = global_position.distance_to(ally.global_position)
				if ally_distance < player_distance:
					target = ally
					player_distance = ally_distance
	
	# Ustaw aktualny cel
	current_target = target
	
	if is_wandering:
		velocity = wander_direction * normal_speed
	else:
		var direction = global_position.direction_to(current_target.global_position)
		velocity = direction * normal_speed
	
	# Ustalanie kierunku patrzenia:
	if is_wandering:
		# Podczas wędrowania patrzymy zgodnie z losowym kierunkiem
		if wander_direction.x > 0:
			sprite.flip_h = true
		elif wander_direction.x < 0:
			sprite.flip_h = false
	else:
		# Patrzymy w stronę aktualnego celu
		if current_target.global_position.x > global_position.x:
			sprite.flip_h = true
		else:
			sprite.flip_h = false

	move_and_slide()

func take_damage(amount):
	health -= amount
	
	# Wyświetlenie liczby obrażeń nad przeciwnikiem
	_show_damage(amount)
	
	if not is_hurt:
		is_hurt = true
		$HitSound.play()
		animation_player.stop()  # Zatrzymaj wszystkie aktywne animacje
		animation_player.play("hurt")
		
		# Uruchom timer do zakończenia animacji hurt
		hurt_timer.start()
	
	if health <= 0:
		died.emit()
		if player.has_method("gain_experience"):
			player.gain_experience(EXPERIENCE_REWARD)
		if get_tree().current_scene.has_method("spawn_power_up"):
			get_tree().current_scene.spawn_power_up(global_position)
		const SMOKE_SCENE = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_SCENE.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		queue_free()

func knock_back(amount: float):
	var move_tween = get_tree().create_tween()
	move_tween.tween_property(
		self,
		"global_position",
		global_position - velocity.normalized() * amount,
		0.1
	)

func _show_damage(amount):
	# Załaduj scenę z damage_number (upewnij się, że ścieżka jest poprawna)
	var damage_number_scene = preload("res://scenes/damage_number.tscn")
	var damage_label = damage_number_scene.instantiate()
	
	# Ustaw tekst etykiety jako wartość otrzymanych obrażeń
	damage_label.text = str(amount)
	
	# Pozycjonujemy etykietę (np. 50 pikseli nad przeciwnikiem)
	damage_label.position = global_position + Vector2(0, -50)
	
	# Dodajemy etykietę do aktualnej sceny
	get_tree().current_scene.add_child(damage_label)

func _on_hurt_timer_timeout():
	is_hurt = false
	if animation_player.current_animation == "hurt":
		play_walk()

func _on_hit_area_body_entered(body):
	if body == player:
		current_target = player
		damage_timer.start()
	elif body.is_in_group("alliance"):
		current_target = body
		damage_timer.start()

func _on_hit_area_body_exited(body):
	if body == current_target:
		damage_timer.stop()
		# Nie resetujemy current_target, ponieważ nadal możemy chcieć strzelać do tego celu

func _on_damage_timer_timeout():
	if current_target and is_instance_valid(current_target):
		if current_target == player:
			player.apply_damage(DAMAGE_RATE)
		elif current_target.has_method("take_damage"):
			current_target.take_damage(DAMAGE_RATE)

func play_walk():
	animation_player.play("walk")

func play_hurt():
	is_hurt = true
	animation_player.play("hurt")
	hurt_timer.start()

# -- Obsługa strzelania:
func _on_shooting_area_body_entered(body):
	if (body == player or body.is_in_group("alliance")) and not is_shooting:
		current_target = body
		start_shooting()

func _on_shooting_area_body_exited(body):
	if body == current_target:
		stop_shooting()

func start_shooting():
	is_shooting = true
	shoot_timer.start()  # Uruchom timer do ciągłego strzelania
	shoot_bullet()       # Wystrzel pierwszy pocisk od razu

func stop_shooting():
	is_shooting = false
	shoot_timer.stop()

func _on_shoot_timer_timeout():
	if is_shooting:
		shoot_bullet()

func shoot_bullet():
	if not current_target or not is_instance_valid(current_target):
		stop_shooting()
		return
		
	# Load and instantiate the bullet scene
	var bullet_scene = preload("res://scenes/bullet_enemy.tscn") 
	var bullet = bullet_scene.instantiate()
	
	# Set position and direction
	bullet.global_position = global_position
	var direction = (current_target.global_position - global_position).normalized()
	bullet.set_direction(direction)
	
	# Add to scene
	get_parent().add_child(bullet)
	
	# Optionally: wander for a short time after shooting
	is_wandering = true
	wander_direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	
	# Stop wandering after 1 second
	await get_tree().create_timer(1.0).timeout
	is_wandering = false
