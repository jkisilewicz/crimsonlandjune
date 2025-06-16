#angry_charge_pixi.gd
extends CharacterBody2D

signal died

@onready var player: CharacterBody2D = $"../Player"
@onready var damage_timer: Timer = $DamageTimer
@onready var hit_area: Area2D = $HitArea
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hurt_timer: Timer = $HurtTimer
@onready var sprite = %RoundEnemyBody
@onready var charge_area: Area2D = %ChargeArea

var health: int = 100
const DAMAGE_RATE = 4.0
const EXPERIENCE_REWARD = 50
var is_hurt = false

# Zmienna do przechowywania aktualnego celu ataku (gracz lub dron)
var current_target = null

# -- Zmienne do szarży i wędrowania:
var normal_speed = 200.0
var charge_speed = 600.0  # czyli 3x szybciej
var is_preparing_charge = false
var is_charging = false
var charge_duration = 3.0  # szarża trwa 3 sekundy
var charge_direction = Vector2.ZERO  # kierunek szarży zapisany przy rozpoczęciu
var is_wandering = false
var wander_direction = Vector2.ZERO  # kierunek wędrowania losowany po szarży

func _ready():
	# Utworzenie Timer'a programowo jeśli nie został dodany w edytorze
	if not has_node("HurtTimer"):
		hurt_timer = Timer.new()
		hurt_timer.name = "HurtTimer"
		hurt_timer.one_shot = true
		hurt_timer.wait_time = 0.5  # Dostosuj do długości animacji hurt
		add_child(hurt_timer)
	
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	play_walk()
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	hit_area.body_exited.connect(_on_hit_area_body_exited)
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	
	# Podłączamy sygnały do obsługi szarży:
	charge_area.body_entered.connect(_on_charge_area_body_entered)
	charge_area.body_exited.connect(_on_charge_area_body_exited)
	
	add_to_group("enemy")  # Dodajemy do grupy enemy, aby drony mogły nas wykrywać

func _physics_process(_delta):
	# Znajdź najbliższy cel (gracz lub ally)
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
	
	# Zachowanie zależne od stanu
	if is_charging:
		velocity = charge_direction * charge_speed
	elif is_preparing_charge:
		velocity = Vector2.ZERO
	elif is_wandering:
		velocity = wander_direction * normal_speed
	else:
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * normal_speed
	
	# Ustalanie kierunku patrzenia:
	if is_charging:
		# Podczas szarży wykorzystujemy zapisany kierunek
		if charge_direction.x > 0:
			sprite.flip_h = false
		elif charge_direction.x < 0:
			sprite.flip_h = true
	elif is_wandering:
		# Podczas wędrowania patrzymy zgodnie z losowym kierunkiem
		if wander_direction.x > 0:
			sprite.flip_h = false
		elif wander_direction.x < 0:
			sprite.flip_h = true
	else:
		# Patrzymy w stronę aktualnego celu
		if target.global_position.x > global_position.x:
			sprite.flip_h = false
		else:
			sprite.flip_h = true

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
		# Rozpocznij zadawanie obrażeń dronowi
		current_target = body
		damage_timer.start()

func _on_hit_area_body_exited(body):
	if body == current_target:
		damage_timer.stop()
		current_target = null

func _on_damage_timer_timeout():
	if current_target and is_instance_valid(current_target):
		if current_target == player:
			if player.has_method("apply_damage"):
				player.apply_damage(DAMAGE_RATE)
		elif current_target.has_method("take_damage"):
			current_target.take_damage(DAMAGE_RATE)

func play_walk():
	animation_player.play("walk")

func play_hurt():
	is_hurt = true
	animation_player.play("hurt")
	hurt_timer.start()

# -- Obsługa szarży:
func _on_charge_area_body_entered(body):
	if (body == player or body.is_in_group("alliance")) and not is_charging and not is_preparing_charge:
		# Ustawienie celu szarży
		current_target = body
		start_charge()

func _on_charge_area_body_exited(_body):
	# Opcjonalnie można tu przerwać szarżę, jeśli chcesz
	# np. is_charging = false, is_preparing_charge = false
	pass

func start_charge():
	is_preparing_charge = true
	velocity = Vector2.ZERO
	move_and_slide()  # Wróg zatrzymuje się od razu
	
	await get_tree().create_timer(1.0).timeout
	
	# Kierunek szarży wybieramy tuż przed startem
	if current_target and is_instance_valid(current_target):
		charge_direction = (current_target.global_position - global_position).normalized()
	else:
		# Jeśli nie ma celu, szarżuj w kierunku gracza
		charge_direction = (player.global_position - global_position).normalized()
	
	animation_player.play("run")
	is_preparing_charge = false
	is_charging = true
	
	await get_tree().create_timer(charge_duration).timeout
	
	is_charging = false
	animation_player.play("walk")
	
	# Po szarży wchodzimy w stan wędrowania na 2 sekundy
	is_wandering = true
	# Losowy kierunek wędrowania (wektor losowy z zakresu [-1,1])
	wander_direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	
	await get_tree().create_timer(2.0).timeout
	
	is_wandering = false
	animation_player.play("walk")
