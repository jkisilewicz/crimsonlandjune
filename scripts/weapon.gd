class_name Weapon
extends Area2D


#region Exported variables
@export var muzzle: Marker2D
@export var weapon_pivot: Marker2D

@export var bullet_scene: PackedScene
@export var is_explosive: bool = false
@export var is_fire_gas_or_money: bool = false
@export var is_wave: bool = false

@export_group("SFX")
@export var shoot_sfx: AudioStreamPlayer2D
@export var reload_sfx: AudioStreamPlayer2D
## Shot sfx to be randomly played when shoothing.
@export var shoot_sfx_path: Array[AudioStream]
## Reload sfx to be randomly played when reloading.
@export var reload_sfx_path: Array[AudioStream]

@export_group("Weapon Stats")
## Bullet shot per second.
@export var fire_rate: float = 1
## How many bullet will be spawned in one shot.
@export var bullet_per_shot: int = 1
## Each shot inaccuracy degree.
@export var bullet_spread: float = 5.0
@export var clip_size: int = 10
@export var reload_time: float = 2.0
@export var damage: int = 25  # Added damage property set to 25
@export_subgroup("Special Bullet")
@export var speed: float
@export var explosion_radius: float
## First value is the minimum and second value is the max value
## for the random time when slowing bullet that can slow down
@export var slow_down_rate: Array[float] = [1, 2]
@export var wave_knock_back_strength: float = 10
## If true, bullet will spawn as a child allowing it to follow the weapon
@export var spawn_bullet_as_child: bool = false
#endregion

#region Local variables
# Need @onready because the clip_size is exported
# therefore the value isn't always the same
@onready var current_clip: int = clip_size
var reload_timer: float = 0.0
var cooldown: float
var target_enemy: Node2D # Node2D as the type is a temporary
var angle_to_target_enemy: float = 0.0
var enemies_in_range := []
#endregion


func _ready() -> void:
	#region Clear null array in the shoot and reload sfx variants
	for i in shoot_sfx_path:
		if i == null:
			shoot_sfx_path.erase(i)
	for i in reload_sfx_path:
		if i == null:
			reload_sfx_path.erase(i)
	#endregion
	
	body_entered.connect(enemy_enter_range)
	body_exited.connect(enemy_exit_range)


func _process(delta: float) -> void:
	# Logic to keep the weapon rotation updated
	_aim_to_closest_enemy()
	_weapon_flip()
	
	# Check if weapon need reload. If reload needed, wait until reload is 
	# finished before continuing
	if reload_timer > 0:
		reload_timer -= delta
		if reload_timer <= 0:
			current_clip = clip_size
		return
	
	# Wait time until the next shot
	if cooldown > 0:
		cooldown -= delta
		return
	
	# Only shoot when there is target and enemies in range
	if target_enemy and enemies_in_range.size() > 0:
		_shoot()


func _aim_to_closest_enemy():
	if enemies_in_range.size() > 0:
		# This variable will act as a record of the closest enemy distance
		var min_distance = INF
		# Set the target enemy to the closest enemy by iterating through
		# the "enemies_in_range" array and set the "target_enemy" if another
		# closer enemy is detected
		for enemy in enemies_in_range:
			if enemy == null or not enemy.is_in_group("enemy"):
				return
			var distance = self.global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				min_distance = distance
				target_enemy = enemy
		
		# Zamiast obracać cały Area2D, obróć tylko WeaponPivot
		weapon_pivot.look_at(target_enemy.global_position)
		
		# Get enemy direction
		var direction_to_enemy = target_enemy.global_position - global_position
		angle_to_target_enemy = atan2(direction_to_enemy.y, direction_to_enemy.x)


func _weapon_flip():
		var is_aiming_left = abs(angle_to_target_enemy) > PI/2
		if is_aiming_left:
			weapon_pivot.scale.y = -1
		else:
			weapon_pivot.scale.y = 1


func enemy_enter_range(body):
	if body.is_in_group("enemy"):
		enemies_in_range.append(body)

func enemy_exit_range(body):
	if body in enemies_in_range:
		enemies_in_range.erase(body)


func _shoot():
	var bullet
	
	# Sprawdź, czy trafienie jest krytyczne
	var is_critical = false
	var crit_damage_multiplier = 2.0  # Mnożnik obrażeń dla trafień krytycznych
	
	# Pobierz gracza i sprawdź szansę na trafienie krytyczne
	var player = get_tree().get_first_node_in_group("player")
	var player_damage_multiplier = 1.0  # Domyślny mnożnik obrażeń
	
	if player and "stats" in player:
		# Pobierz mnożnik obrażeń gracza
		if "guns_damage" in player.stats:
			player_damage_multiplier = player.stats["guns_damage"]
			
		# Sprawdź szansę na trafienie krytyczne
		if "guns_crit_chance" in player.stats:
			var crit_roll = randf()
			is_critical = crit_roll < player.stats["guns_crit_chance"]
	
	# Spawn some amount of bullet at once, if allowed
	for i in range(bullet_per_shot):
		# Instantiate bullet from the scene.
		bullet = bullet_scene.instantiate()
		
		# Set bullet damage, z uwzględnieniem mnożnika gracza i trafienia krytycznego
		if bullet.has_method("set_damage"):
			# Oblicz końcowe obrażenia: podstawowe * mnożnik gracza * (mnożnik krytyczny, jeśli trafienie krytyczne)
			var final_damage = damage * player_damage_multiplier
			if is_critical:
				final_damage *= crit_damage_multiplier
			
			# Zaokrąglij obrażenia do liczby całkowitej (opcjonalnie)
			final_damage = int(final_damage)
			
			bullet.set_damage(final_damage)
		
		if bullet.has_method("set_speed") and speed != 0:
			bullet.set_speed(speed)
		
		 # Jeśli trafienie jest krytyczne, zmień wygląd pocisku
		if is_critical and bullet.has_method("set_critical"):
			bullet.set_critical(true)
		elif is_critical:
			# Jeśli pocisk nie ma metody set_critical, zmień jego wygląd bezpośrednio
			bullet.modulate = Color(1.0, 0.5, 0.0)  # Pomarańczowy kolor
			bullet.scale *= 1.2  # Powiększ pocisk
		
		# Setup bullet spread.
		var deviation = deg_to_rad(randf_range(-bullet_spread, bullet_spread))
		
		# Setup explosive bullet if weapon set as explosive
		if is_explosive:
			_set_explosive_weapon(bullet, speed, explosion_radius)
		
		# Setup fire bullet if weapon set as fire
		if is_fire_gas_or_money:
			_set_plasma_weapon(bullet, speed, slow_down_rate)
		
		# Setup wave bullet
		if is_wave:
			_set_knock_back_strength(bullet, speed, wave_knock_back_strength)
		
		# Set bullet start position on the weapon muzzle.
		# If "muzzle" is not assign, start bullet position on the pivot point.
		# Also apply bullet spread.
		if muzzle:
			bullet.global_position = muzzle.global_position
			bullet.rotation = muzzle.global_rotation + deviation
		else:
			bullet.global_position = weapon_pivot.global_position
			bullet.rotation = weapon_pivot.global_rotation + deviation
		
		# Add bullet to the tree.
		if spawn_bullet_as_child == false:
			get_tree().current_scene.add_child(bullet)
		else:
			add_child(bullet)
	
	# Play random shot sfx
	shoot_sfx.stream = shoot_sfx_path.pick_random()
	shoot_sfx.play()
	
	current_clip -= 1
	if current_clip <= 0:
		if player and "stats" in player and "guns_reload_speed" in player.stats:
			# Zastosuj mnożnik szybkości przeładowania - im wyższa wartość, tym krótszy czas
			reload_timer = reload_time / player.stats["guns_reload_speed"]
		else:
			reload_timer = reload_time
			
		reload_sfx.stream = reload_sfx_path.pick_random()
		reload_sfx.play()
	
	# Set weapon cooldown
	if player:
		cooldown = 1 / (fire_rate * player.stats["guns_attack_speed"])
	else:
		cooldown = 1 / fire_rate


func _set_speed(bullet, _speed: float):
	if bullet.has_method("set_speed"):
		bullet.set_speed(_speed)


func _set_explosive_weapon(bullet, _speed: float, _explosion_radius: float):
	if bullet.has_method("set_explosion_radius"):
		bullet.set_explosion_radius(_explosion_radius)
	
	_set_speed(bullet, _speed)


func _set_plasma_weapon(bullet, _speed: float, _slow_down_rate: Array[float]):
	if bullet.has_method("set_slow_down_rate"):
		bullet.set_slow_down_rate(_slow_down_rate)
	
	_set_speed(bullet, _speed)


func _set_knock_back_strength(bullet, _speed: float, knock_back_strength: float):
	if bullet.has_method("set_knock_back_strength"):
		bullet.set_knock_back_strength(knock_back_strength)
	
	_set_speed(bullet, speed)
