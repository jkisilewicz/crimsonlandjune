# turret-bullet.gd
extends Node2D

@export var shoot_interval = 0.1  # Czas między strzałami
@export var rotation_speed = 3.0  # Prędkość obracania się działka
@export var detection_radius = 600.0  # Promień wykrywania wrogów
@export var bullet_damage = 15.0  # Obrażenia zadawane przez pojedynczy pocisk
@export var max_health = 100  # Maksymalne zdrowie działka zamiast lifetime

# Referencje do elementów UI zdrowia
@onready var health_progress_bar: ProgressBar = %HealthProgressBar
@onready var health_text_label: Label = %HealthText
@onready var hit_area: Area2D = $HitArea  # Referencja do obszaru kolizji dla wrogów
@onready var damage_timer: Timer = $DamageTimer  # Timer do zadawania obrażeń

var bullet_scene = preload("res://turrets/bullet/turret_rifle_bullet.tscn")
var shoot_timer
var hurt_timer
var target = null
var current_health = max_health
var is_hurt = false
var current_target = null  # Do przechowywania atakującego wroga

func _ready():
	# Dodaj działko do grupy turrets, jeśli będzie potrzebna
	add_to_group("turrets")
	add_to_group("alliance")  # Dodaj do grupy przyjaciół, aby wrogowie mogli atakować
	
	# Utwórz timer do strzelania
	shoot_timer = Timer.new()
	shoot_timer.wait_time = shoot_interval
	shoot_timer.one_shot = false
	shoot_timer.autostart = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)
	
	# Utwórz timer efektu otrzymania obrażeń
	hurt_timer = Timer.new()
	hurt_timer.wait_time = 0.3
	hurt_timer.one_shot = true
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	add_child(hurt_timer)
	
	# Utwórz timer zadawania obrażeń, jeśli nie istnieje
	if not has_node("DamageTimer"):
		var timer = Timer.new()
		timer.name = "DamageTimer"
		timer.wait_time = 0.5  # Co pół sekundy zadaje obrażenia
		timer.one_shot = false
		add_child(timer)
		damage_timer = timer
		
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	
	# Połącz sygnały HitArea, jeśli obszar istnieje
	if has_node("HitArea"):
		hit_area = $HitArea
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		hit_area.body_exited.connect(_on_hit_area_body_exited)
	else:
		# Jeśli nie ma HitArea, utwórz je programowo
		var area = Area2D.new()
		area.name = "HitArea"
		add_child(area)
		hit_area = area
		
		# Dodaj kształt kolizji taki sam jak główna kolizja
		if has_node("CollisionShape2D"):
			var collision_shape = $CollisionShape2D.duplicate()
			area.add_child(collision_shape)
		else:
			# Jeśli nie ma CollisionShape2D, dodaj domyślny kształt
			var collision = CollisionShape2D.new()
			var shape = CircleShape2D.new()
			shape.radius = 50.0
			collision.shape = shape
			area.add_child(collision)
		
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		hit_area.body_exited.connect(_on_hit_area_body_exited)
	
	# Pobierz mnożnik siły od gracza, jeśli istnieje
	var player = get_tree().get_first_node_in_group("player")
	if player and "stats" in player:
		if "turret_power" in player.stats:
			bullet_damage *= player.stats["turret_power"]
		
		# Pobierz mnożnik zdrowia od gracza, jeśli istnieje
		if "friend_health" in player.stats:
			max_health += player.stats["friend_health"]
			current_health = max_health
	
	# Inicjalizacja interfejsu zdrowia
	if health_progress_bar:
		health_progress_bar.max_value = max_health
		update_health_ui()

func update_health_ui():
	# Aktualizuje pasek zdrowia i etykietę tekstową
	if health_progress_bar:
		health_progress_bar.value = current_health
	
	if health_text_label:
		health_text_label.text = str(int(current_health))

func _process(delta):
	find_target()
	rotate_towards_target(delta)

func find_target():
	# Resetuj obecny cel, jeśli nie jest już ważny
	if target and (!is_instance_valid(target) or !target.is_in_group("enemy")):
		target = null
	
	# Jeśli nie mamy celu, szukamy nowego
	if not target:
		var enemies = get_tree().get_nodes_in_group("enemy")
		if enemies.size() == 0:
			# Sprawdź również grupę "slime" jako fallback
			enemies = get_tree().get_nodes_in_group("slime")
			if enemies.size() == 0:
				return
		
		var closest_enemy = null
		var closest_distance = detection_radius
		
		for enemy in enemies:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
		
		target = closest_enemy

func rotate_towards_target(delta):
	if target:
		var direction = global_position.direction_to(target.global_position)
		var target_angle = direction.angle()
		
		# NIE obracamy Sprite2D - tylko ShootPoint
		var shoot_point = %ShootPoint
		if shoot_point:
			var current_shoot_angle = shoot_point.rotation
			var new_shoot_angle = lerp_angle(current_shoot_angle, target_angle, rotation_speed * delta)
			shoot_point.rotation = new_shoot_angle

func _on_shoot_timer_timeout():
	if target:
		shoot()

func shoot():
	# Stwórz pocisk
	var bullet = bullet_scene.instantiate()
	var shoot_point = %ShootPoint
	bullet.global_position = shoot_point.global_position
	bullet.rotation = shoot_point.rotation  # Używamy rotacji ShootPoint, nie Sprite2D
	
	# Ustaw obrażenia pocisku
	if bullet.has_method("set_damage"):
		bullet.set_damage(bullet_damage)
	
	# Dodaj pocisk do sceny
	get_tree().get_current_scene().add_child(bullet)
	
	# Odtwórz dźwięk strzału, jeśli istnieje
	if has_node("sfx_shoot"):
		%sfx_shoot.play()

# Obsługa HitArea do wykrywania wrogów
func _on_hit_area_body_entered(body):
	# Sprawdź, czy kolizja jest z wrogiem
	if body.is_in_group("enemy") or body.is_in_group("slime"):
		current_target = body
		damage_timer.start()
		print("Działko: Kolizja z wrogiem - start zadawania obrażeń")

func _on_hit_area_body_exited(body):
	if body == current_target:
		damage_timer.stop()
		current_target = null
		print("Działko: Wyjście z obszaru - stop zadawania obrażeń")

func _on_damage_timer_timeout():
	if current_target and is_instance_valid(current_target):
		# Wróg zadaje obrażenia działku
		take_damage(4.0)  # Standardowa wartość obrażeń od wroga

# System zdrowia i otrzymywania obrażeń
func take_damage(amount):
	current_health -= amount
	
	# Aktualizacja UI zdrowia
	update_health_ui()
	
	# Wyświetlenie liczby obrażeń nad działkiem
	_show_damage(amount)
	
	# Efekt otrzymania obrażeń
	if not is_hurt:
		is_hurt = true
		if has_node("sfx_reload"):
			$sfx_reload.play()  # Dźwięk otrzymania obrażeń
		
		# Wizualny efekt otrzymania obrażeń (pulsowanie kolorem)
		var sprite = $Sprite2D
		if sprite:
			var tween = create_tween()
			tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
			tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)
		
		hurt_timer.start()
	
	# Sprawdź czy działko zostało zniszczone
	if current_health <= 0:
		# Stwórz efekt eksplozji
		create_explosion_effect()
		
		# Usuń działko
		queue_free()

func _on_hurt_timer_timeout():
	is_hurt = false

func _show_damage(amount):
	# Załaduj scenę z damage_number
	var damage_number_scene = load("res://scenes/damage_number.tscn")
	if damage_number_scene:
		var damage_label = damage_number_scene.instantiate()
		
		# Ustaw tekst etykiety jako wartość otrzymanych obrażeń
		damage_label.text = str(amount)
		
		# Pozycjonujemy etykietę nad działkiem
		damage_label.position = global_position + Vector2(0, -50)
		
		# Dodajemy etykietę do aktualnej sceny
		get_tree().get_current_scene().add_child(damage_label)

func create_explosion_effect():
	# Tutaj możesz dodać kod tworzący efekt eksplozji
	var explosion_scene = load("res://smoke_explosion/smoke_explosion.tscn")
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().get_current_scene().add_child(explosion)
		explosion.global_position = global_position
