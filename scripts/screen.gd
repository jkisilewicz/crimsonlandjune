#screen.gd
extends Node2D

const ANGRY_CHARGE_PIXI = preload("res://characters/angry_charge_pixi/angry_charge_pixi.tscn")
const FIXI = preload("res://characters/fixi/fixi.tscn")
const DIXI = preload("res://characters/dixi/dixi.tscn")
const ROUND_ENEMY_SCENE = preload("res://characters/round_enemy/round_enemy.tscn")

@onready var monster_pool := [
		ANGRY_CHARGE_PIXI, 
		FIXI,
		DIXI, 
		ROUND_ENEMY_SCENE
]

@onready var path_follow = %EnemySpawnPoint

var player

var max_enemy_spawn := [
		20, 22, 24, 27, 29, 32, 35, 37, 40, 43,
		45, 48, 50, 52, 55, 58, 61, 63, 66, 68,
		71, 73, 76, 78, 81, 84, 87, 90, 92, 95,
		97, 100, 102, 105, 108, 111, 114, 116, 119, 122,
		125, 127, 130, 133, 136, 139, 142, 145, 147, 150
]

var last_death_pos: Vector2

var monster_on_scene: int = 0

var monster_spawn_timer: float = 1.0 
var dixi_spawned: int = 0  
var monster_spawned: int = 0  
var cookie_monster_spawned: int = 0 
var round_enemy_spawned: int = 0 

var monster_dead: int = 0 

func _ready():
	Engine.max_fps = 0
	
	player = get_tree().get_first_node_in_group("player")
	
	spawn_monster()


func _process(_delta):
	pass


func spawn_monster():
	if monster_on_scene < max_enemy_spawn[player.level - 1]:
		var monster_to_spawn: PackedScene = monster_pool.pick_random()
		var monster = monster_to_spawn.instantiate()
		path_follow.progress_ratio = randf()
		monster.global_position = path_follow.global_position
		add_child(monster)
		monster_spawned += 1 
		monster_on_scene += 1
		if monster.has_signal("died"):
			monster.connect("died", _on_monster_died)
	
	# Tworzymy timer, który respektuje pauzę
	var timer = get_tree().create_timer(1, true)  # Dodajemy parametr true, aby timer respektował pauzę
	timer.timeout.connect(spawn_monster)
	
func _on_monster_died():
	monster_dead += 1
	monster_on_scene -= 1


func spawn_power_up(_position: Vector2) -> void:
	last_death_pos = _position
	
	if randf() < 0.05:
		if Powerups.powerups_pool.is_empty():
			return
		
		var power_up_scene: PackedScene
		power_up_scene = load(Powerups.powerups_pool.pick_random())
		
		var power_up = power_up_scene.instantiate()
		add_child(power_up)
		power_up.global_position = position
