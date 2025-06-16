extends CharacterBody2D

@export var follow_distance = 150.0
@export var movement_speed = 200.0
@export var shoot_interval = 0.8
@export var detection_radius = 800.0
@export var bullet_damage = 10.0
@export var max_health = 100

@onready var health_progress_bar: ProgressBar = %HealthProgressBar
@onready var health_text_label: Label = %HealthText

var bullet_scene = preload("res://turrets/bullet/turret_rifle_bullet.tscn")
var target = null
var player = null
var shoot_timer
var hurt_timer
var current_health = max_health
var is_hurt = false
var sprite_node = null

func _ready():
	add_to_group("friends")
	add_to_group("alliance")

	player = get_tree().get_first_node_in_group("player")
	print("Znaleziono gracza: ", player != null)

	shoot_timer = Timer.new()
	shoot_timer.wait_time = shoot_interval
	shoot_timer.one_shot = false
	shoot_timer.autostart = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)

	hurt_timer = Timer.new()
	hurt_timer.wait_time = 0.3
	hurt_timer.one_shot = true
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	add_child(hurt_timer)

	print("Czy ShootPoint istnieje: ", has_node("%ShootPoint"))

	if player and "stats" in player:
		if "friend_damage" in player.stats:
			bullet_damage *= player.stats["friend_damage"]
			print("Obrażenia drona po modyfikacji: ", bullet_damage)

		max_health += player.stats.get("friend_max_hp", 0.0)
		current_health = max_health
		print("Zdrowie drona po modyfikacji: ", max_health)

	if health_progress_bar:
		health_progress_bar.max_value = max_health
		update_health_ui()
	else:
		print("OSTRZEŻENIE: Nie znaleziono HealthProgressBar (%HealthProgressBar) dla drona.")

	if health_text_label:
		update_health_ui()
	else:
		print("OSTRZEŻENIE: Nie znaleziono HealthText (%HealthText) dla drona.")

	sprite_node = get_node_or_null("Sprite2D")

	if not sprite_node:
		sprite_node = get_node_or_null("%Sprite2D")

	if not sprite_node:
		var potential_paths = ["DroneBody/Sprite2D", "Body/Sprite2D", "Visual/Sprite2D"]
		for path in potential_paths:
			sprite_node = get_node_or_null(path)
			if sprite_node:
				break

	if not sprite_node:
		for child in get_children_recursive():
			if child is Sprite2D:
				sprite_node = child
				break

	if sprite_node:
		print("Znaleziono sprite drona: ", sprite_node.name, " pod ścieżką: ", sprite_node.get_path())
	else:
		print("OSTRZEŻENIE: Nie znaleziono żadnego Sprite2D dla drona. Obracanie nie będzie działać.")
		print("Lista wszystkich węzłów drona:")
		for child in get_children_recursive():
			print("- ", child.name, " (", child.get_class(), ")")

func update_health_ui():
	if health_progress_bar:
		health_progress_bar.value = current_health

	if health_text_label:
		health_text_label.text = str(int(current_health))

func _physics_process(delta):
	follow_player(delta)

	find_target()
	if target:
		rotate_shoot_point_to_target()

	if sprite_node:
		if velocity.x < -5.0:
			sprite_node.flip_h = true
		elif velocity.x > 5.0:
			sprite_node.flip_h = false
	else:
		sprite_node = find_sprite_node()

func find_sprite_node():
	for child in get_children():
		if child is Sprite2D:
			print("Znaleziono Sprite2D podczas działania: ", child.name)
			return child

	for child in get_children_recursive():
		if child is Sprite2D:
			print("Znaleziono Sprite2D rekurencyjnie podczas działania: ", child.name)
			return child

	return null

func follow_player(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			velocity = Vector2.ZERO
			move_and_slide()
			return

	var vector_to_drone = global_position - player.global_position
	var distance_to_player = vector_to_drone.length()

	var min_distance = 10.0
	var push_force_multiplier = 1.2

	if distance_to_player < min_distance and distance_to_player > 0.1:
		var push_direction = vector_to_drone.normalized()
		velocity = push_direction * movement_speed * push_force_multiplier
	else:
		var target_position
		if player.velocity.length_squared() < 150:
			var side_offset = vector_to_drone.normalized() * follow_distance
			if vector_to_drone.length_squared() < 1.0:
				side_offset = Vector2(follow_distance, 0)
			target_position = player.global_position + side_offset
		else:
			var player_direction = player.velocity.normalized()
			var side_vector = player_direction.rotated(PI/2)
			target_position = player.global_position - player_direction * follow_distance * 0.7 + side_vector * follow_distance * 0.5

		var direction_to_target = target_position - global_position
		var distance_to_target = direction_to_target.length()

		if distance_to_target > 10:
			var desired_velocity = direction_to_target.normalized() * movement_speed
			var speed_factor = clamp(distance_to_target / 150.0, 0.1, 1.0)
			velocity = desired_velocity * speed_factor
		else:
			velocity = Vector2.ZERO

	move_and_slide()

func find_target():
	target = null
	var enemies_group = get_tree().get_nodes_in_group("enemy")
	var slimes_group = get_tree().get_nodes_in_group("slime")
	var potential_targets = enemies_group + slimes_group

	if potential_targets.size() == 0:
		return

	var closest_enemy = null
	var closest_distance_sq = INF

	for enemy in potential_targets:
		if is_instance_valid(enemy) and enemy is Node2D:
			var distance_sq = global_position.distance_squared_to(enemy.global_position)
			if distance_sq < closest_distance_sq:
				closest_distance_sq = distance_sq
				closest_enemy = enemy

	if closest_enemy and closest_distance_sq <= detection_radius * detection_radius:
		target = closest_enemy

func rotate_shoot_point_to_target():
	if target and is_instance_valid(target):
		var shoot_point = get_node_or_null("%ShootPoint")
		if shoot_point:
			var direction_to_target = global_position.direction_to(target.global_position)
			shoot_point.global_rotation = direction_to_target.angle()
		else:
			print("OSTRZEŻENIE: Nie znaleziono węzła %ShootPoint w dronie.")

func _on_shoot_timer_timeout():
	if target and is_instance_valid(target):
		shoot()

func shoot():
	if not target or not is_instance_valid(target):
		return

	var shoot_point = get_node_or_null("%ShootPoint")
	if not shoot_point:
		print("Brak punktu wystrzału (%ShootPoint)!")
		return

	var bullet = bullet_scene.instantiate()
	if not bullet:
		print("BŁĄD: Nie udało się zinstancjonować sceny pocisku:", bullet_scene.resource_path)
		return

	bullet.global_position = shoot_point.global_position
	bullet.global_rotation = shoot_point.global_rotation

	if bullet.has_method("set_damage"):
		bullet.set_damage(bullet_damage)
	else:
		print("OSTRZEŻENIE: Pocisk nie ma metody 'set_damage'.")

	var bullet_container = get_tree().get_first_node_in_group("bullet_container")
	if bullet_container:
		bullet_container.add_child(bullet)
	else:
		get_tree().get_current_scene().add_child(bullet)
		print("OSTRZEŻENIE: Brak węzła w grupie 'bullet_container'. Dodano pocisk do roota sceny.")

	var sfx_player = get_node_or_null("%sfx_shoot")
	if sfx_player and sfx_player is AudioStreamPlayer2D:
		sfx_player.play()

func take_damage(amount):
	if current_health <= 0:
		return

	current_health -= amount
	current_health = max(current_health, 0)

	update_health_ui()
	_show_damage(amount)

	if not is_hurt:
		is_hurt = true
		var sfx_hurt = get_node_or_null("%sfx_hurt")
		if sfx_hurt and sfx_hurt is AudioStreamPlayer:
			sfx_hurt.play()

		if sprite_node:
			var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite_node, "modulate", Color(1, 0.3, 0.3, 0.7), 0.1).from_current()
			tween.tween_property(sprite_node, "scale", sprite_node.scale * 1.1, 0.1).from_current()
			tween.chain()
			tween.tween_property(sprite_node, "modulate", Color(1, 1, 1, 1), 0.2)
			tween.tween_property(sprite_node, "scale", sprite_node.scale, 0.2)

		hurt_timer.start()

	if current_health <= 0:
		_destroy_drone()

func _on_hurt_timer_timeout():
	is_hurt = false

func _show_damage(amount):
	var damage_number_scene = load("res://scenes/damage_number.tscn")
	if not damage_number_scene:
		print("BŁĄD: Nie można załadować sceny damage_number.tscn")
		return

	var damage_label = damage_number_scene.instantiate()
	if not damage_label or not damage_label is Label:
		print("BŁĄD: Zinstancjonowany damage_number nie jest typu Label.")
		return

	damage_label.text = str(int(amount))
	damage_label.global_position = global_position + Vector2(randf_range(-15, 15), -50 + randf_range(-5, 5))
	get_tree().get_current_scene().add_child(damage_label)

func create_explosion_effect():
	var explosion_scene = load("res://smoke_explosion/smoke_explosion.tscn")
	if not explosion_scene:
		print("BŁĄD: Nie można załadować sceny smoke_explosion.tscn")
		return

	var explosion = explosion_scene.instantiate()
	if explosion:
		var parent_node = get_parent()
		if parent_node:
			parent_node.add_child(explosion)
			explosion.global_position = global_position
		else:
			get_tree().get_current_scene().add_child(explosion)
			explosion.global_position = global_position

func _destroy_drone():
	print("Dron zniszczony!")
	var sfx_destroy = get_node_or_null("%sfx_destroy")
	if sfx_destroy and sfx_destroy is AudioStreamPlayer:
		sfx_destroy.play()

	create_explosion_effect()
	queue_free()

func get_children_recursive():
	var all_children = []
	for child in get_children():
		all_children.append(child)
		if child.get_child_count() > 0:
			all_children.append_array(_get_children_recursive(child))
	return all_children

func _get_children_recursive(node):
	var children = []
	for child in node.get_children():
		children.append(child)
		if child.get_child_count() > 0:
			children.append_array(_get_children_recursive(child))
	return children
