#screen.gd
extends Node2D

const ANGRY_CHARGE_PIXI = preload("res://characters/angry_charge_pixi/angry_charge_pixi.tscn")
const FIXI = preload("res://characters/fixi/fixi.tscn")
const DIXI = preload("res://characters/dixi/dixi.tscn")
const ROUND_ENEMY_SCENE = preload("res://characters/round_enemy/round_enemy.tscn")

@onready var path_follow = %PathFollow2D

var monster_spawn_timer: float = 1.0 
var dixi_spawned: int = 0  
var monster_spawned: int = 0  
var cookie_monster_spawned: int = 0 
var round_enemy_spawned: int = 0 

var monster_dead: int = 0 

func _ready():
	Engine.max_fps = 0  
	spawn_monster()
	
func _process(delta):
	pass


func spawn_round_enemy():
	var round_enemy = ROUND_ENEMY_SCENE.instantiate()
	add_child(round_enemy)
	path_follow.progress_ratio = randf()
	round_enemy.global_position = path_follow.global_position
	round_enemy_spawned += 1  
	if round_enemy.has_signal("round_enemy_died"):
		round_enemy.connect("round_enemy_died", _on_round_enemy_died)
	var timer = get_tree().create_timer(1.5)  
	timer.timeout.connect(spawn_round_enemy)
func _on_round_enemy_died():
	monster_dead += 1


func spawn_dixi():
	var dixi = DIXI.instantiate()
	add_child(dixi)
	path_follow.progress_ratio = randf()
	dixi.global_position = path_follow.global_position
	dixi_spawned += 1
	if dixi.has_signal("dixi_died"):
		dixi.connect("dixi_died", _on_dixi_died)
	var timer = get_tree().create_timer(1.5)  
	timer.timeout.connect(spawn_dixi)
func _on_dixi_died():
	monster_dead += 1


func spawn_cookie_monster():
	var cookie_monster = ANGRY_CHARGE_PIXI.instantiate()
	add_child(cookie_monster)
	path_follow.progress_ratio = randf()
	cookie_monster.global_position = path_follow.global_position
	cookie_monster_spawned += 1 
	if cookie_monster.has_signal("cookie_monster_died"):
		cookie_monster.connect("cookie_monster_died", _on_cookie_monster_died)
	var timer = get_tree().create_timer(1.5)  
	timer.timeout.connect(spawn_cookie_monster)
func _on_cookie_monster_died():
	monster_dead += 1
	

func spawn_monster():
	var monster = FIXI.instantiate()
	add_child(monster)
	path_follow.progress_ratio = randf()
	monster.global_position = path_follow.global_position
	monster_spawned += 1 
	if monster.has_signal("monster_died"):
		monster.connect("monster_died", _on_monster_died)
	var timer = get_tree().create_timer(1.5)  
	timer.timeout.connect(spawn_monster)
func _on_monster_died():
	monster_dead += 1

func spawn_power_up(position: Vector2) -> void:
	# Ustawiamy szansę pojawienia się power-upa (np. 20%)
	if randi() % 100 < 20:
		var power_up_scene: PackedScene
		match randi() % 4:
			0:
				power_up_scene = preload("res://weapons/rifle/rifle_power_up.tscn")
		var power_up = power_up_scene.instantiate()
		add_child(power_up)
		power_up.global_position = position
