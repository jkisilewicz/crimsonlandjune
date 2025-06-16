class_name Beamer
extends Area2D

@export var damage_per_second: int = 50

@onready var laser_ray: RayCast2D = %LaserRay
@onready var laser_visual: Line2D = %LaserVisual
@onready var weapon_pivot: Marker2D = %WeaponPivot
@onready var damage_timer: Timer = $DamageTimer
@onready var shooting_start: Marker2D = %ShootingStart
@onready var sfx_shoot: AudioStreamPlayer2D = %sfx_shoot

var enemies_in_range: Array = []
var target_enemy: Node2D = null
var angle_to_target_enemy
var effected_enemy


func _ready() -> void:
	damage_timer.timeout.connect(_damage_enemy)


func _process(_delta: float) -> void:
	enemies_in_range = get_overlapping_bodies()
	
	target_enemy = _get_target_enemy()
	
	if target_enemy:
		_rotate_to_target_enemy()
		_shoot()
	else:
		_deactivate_laser()
	
	_adjust_laser_visual()


func _shoot():
	_activate_laser()
	if laser_ray.is_colliding():
		effected_enemy = laser_ray.get_collider()
		if damage_timer.time_left <= 0:
			print("timer start")
			damage_timer.start(0.25)


func _damage_enemy():
	print("damage")
	if effected_enemy == null:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	var damage_multiplier
	
	if effected_enemy.has_method("take_damage"):
		if "guns_damage" in player.stats:
			damage_multiplier = player.stats["guns_damage"]
		
		effected_enemy.take_damage(damage_per_second * damage_multiplier * 0.25)
	
	if effected_enemy.has_method("knock_back"):
		effected_enemy.knock_back(5)


func _activate_laser():
	if !sfx_shoot.playing:
		if sfx_shoot.stream_paused:
			sfx_shoot.stream_paused = false
		else:
			sfx_shoot.play()
	
	laser_ray.visible = true
	laser_visual.visible = true

func _deactivate_laser():
	sfx_shoot.stream_paused = true
	
	laser_ray.visible = false
	laser_visual.visible = false


func _adjust_laser_visual():
	var hit_pos = (to_local(laser_ray.get_collision_point()) 
			if laser_ray.is_colliding()
			else laser_visual.get_point_position(0)
	)
	laser_visual.points = [to_local(shooting_start.global_position), 
			hit_pos]


func _get_target_enemy() -> Node2D:
	var closest_enemy
	
	var min_distance = INF
	
	for enemy in enemies_in_range:
		var distance = self.global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_enemy = enemy
	
	return closest_enemy


func _rotate_to_target_enemy():
	# Zamiast obracać cały Area2D, obróć tylko WeaponPivot
	weapon_pivot.look_at(target_enemy.global_position)
	
	# Get enemy direction
	var direction_to_enemy = target_enemy.global_position - global_position
	angle_to_target_enemy = atan2(direction_to_enemy.y, direction_to_enemy.x)
	
	_weapon_flip()


func _weapon_flip():
	var is_aiming_left = abs(angle_to_target_enemy) > PI/2
	if is_aiming_left:
		weapon_pivot.scale.y = -1
	else:
		weapon_pivot.scale.y = 1


func _on_body_exited(body: Node2D) -> void:
	if body == target_enemy:
		target_enemy = null
	
	if body == effected_enemy:
		effected_enemy = null
