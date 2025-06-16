extends Node2D


@export var bullet: PackedScene
## How many bullets will be fired in a second - bullet/sec.
## If 0.5, 1 bullet will be fired every 2 seconds.
@export var fire_rate: float = 1

@export var cooldown: Cooldown

var targeted_enemy: Node2D
var enemies_in_range: Array

@onready var shooting_range: Area2D = $ShootingRange
@onready var bullet_spawn_pos: Marker2D = %BulletSpawnPos


func _process(_delta: float) -> void:
	_add_enemies_in_range()
	
	if not enemies_in_range.is_empty() and targeted_enemy == null:
		# Create a temporary clean list of valid enemies
		var valid_enemies := []
		for item in enemies_in_range:
			if is_instance_valid(item):
				valid_enemies.append(item)
		
		# Update the original list if you want
		enemies_in_range = valid_enemies
		
		# Pick a random target from valid enemies
		if not enemies_in_range.is_empty():
			targeted_enemy = enemies_in_range.pick_random()
	
	if targeted_enemy != null:
		if not cooldown.is_ready():
			return
		var rad_to_target = (bullet_spawn_pos.global_position.direction_to(
				targeted_enemy.global_position)).angle()
		var bullet = Spawner.spawn_object(bullet, bullet_spawn_pos.global_position, rad_to_target)
		
		if bullet.has_method("set_speed"):
			bullet.set_speed(500)
		
		cooldown.trigger(1/fire_rate)


func _add_enemies_in_range():
	for body in shooting_range.get_overlapping_bodies():
		if body in enemies_in_range:
			continue
		
		if body.is_in_group("enemy"):
			enemies_in_range.append(body)
