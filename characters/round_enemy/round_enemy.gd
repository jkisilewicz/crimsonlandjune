#round_enemy.gd
extends CharacterBody2D

signal died

@onready var player: CharacterBody2D = $"../Player"
@onready var damage_timer: Timer = $DamageTimer
@onready var hit_area: Area2D = $HitArea
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hurt_timer: Timer = $HurtTimer  # Dodaj nowy Timer do sceny!
@onready var sprite = %RoundEnemyBody  # Zakładam, że sprite nazywa się Sprite2D

var health: int = 100
const DAMAGE_RATE = 4.0
const EXPERIENCE_REWARD = 50
var is_hurt = false

# Zmienna do przechowywania aktualnego celu ataku
var current_target = null

func _ready():
	# Dodaj wroga do grupy enemy, aby drony mogły go wykrywać
	add_to_group("enemy")
	
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
	
	# Poruszaj się w kierunku celu
	var direction = global_position.direction_to(current_target.global_position)
	velocity = direction * 200.0
	
	if velocity.x > 0:  # Jeśli porusza się w prawo
		sprite.flip_h = true  # Odwróć sprite horyzontalnie
	elif velocity.x < 0:  # Jeśli porusza się w lewo
		sprite.flip_h = false  # Nie odwracaj sprite'a
	
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
	
	# Dodajemy etykietę do aktualnej sceny (lub do wybranego węzła)
	get_tree().get_current_scene().add_child(damage_label)

func _on_hurt_timer_timeout():
	is_hurt = false
	if animation_player.current_animation == "hurt":
		play_walk()

func _on_hit_area_body_entered(body):
	if body == player:
		current_target = player
		damage_timer.start()
		print("Slime: Kolizja z graczem - start zadawania obrażeń")
	elif body.is_in_group("alliance"):
		current_target = body
		damage_timer.start()
		print("Slime: Kolizja z przyjacielem - start zadawania obrażeń")

func _on_hit_area_body_exited(body):
	if body == current_target:
		damage_timer.stop()
		current_target = null
		print("Slime: Wyjście z obszaru - stop zadawania obrażeń")

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
