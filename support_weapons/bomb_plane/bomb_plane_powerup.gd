extends Area2D

@export var spawn_interval = 5.0
@export var plane_life_time: float = 10
@export var plane_speed: float = 1000
@export var plane_drop_rate: int = 3

var bomb_plane_scene = preload("res://support_weapons/bomb_plane/bomb_plane.tscn")

var is_active = false

var spawn_path_point: PathFollow2D # Will be assigned in _ready()

@onready var timer: Timer = $Timer


func _ready() -> void:
	if not body_entered.is_connected(_enable_powerup):
		body_entered.connect(_enable_powerup)
	if not timer.timeout.is_connected(_spawn_bomb_plane):
		timer.timeout.connect(_spawn_bomb_plane)
	
	# Erase this powerup from the powerup pool for dropping
	Powerups.powerups_pool.erase("res://support_weapons/bomb_plane/bomb_plane_powerup.tscn")
	
	if get_tree().current_scene.has_node("Player/Camera2D2/PlaneSpawnPath/PlaneSpawnPoint"):
		spawn_path_point = (
			get_tree().current_scene.get_node("Player/Camera2D2/PlaneSpawnPath/PlaneSpawnPoint")
		)


func _enable_powerup(body: Node2D):
	if body.is_in_group("player") and not is_active:
		is_active = true
		monitoring = false
		monitorable = false
		$Sprite2.hide()
		_spawn_bomb_plane()


func _spawn_bomb_plane():
	var bomb_plane: BomberPlane = bomb_plane_scene.instantiate()
	
	spawn_path_point.progress_ratio = randf()
	bomb_plane.global_position = spawn_path_point.global_position
	
	var player = get_tree().get_first_node_in_group("player")
	bomb_plane.look_at(player.global_position)
	
	print("life_timer")
	bomb_plane.life_time_duration = plane_life_time
	
	if bomb_plane.speed:
		bomb_plane.speed = plane_speed
	
	if bomb_plane.drop_rate:
		bomb_plane.drop_rate = plane_drop_rate
	
	add_child(bomb_plane)
	
	await child_exiting_tree
	timer.start(spawn_interval)
