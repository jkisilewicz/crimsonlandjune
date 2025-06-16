class_name BomberPlane
extends Node2D


const dumb_bomb_scene: PackedScene = preload("res://support_weapons/bomb_plane/dumb_bomb/dumb_bomb.tscn")

@export var speed := 500.0
## Determines how many bombs will be drop per second.
@export var drop_rate: float = 2

var life_time_duration: float

var can_drop_bomb: bool = false

var player: Player

@onready var timer: Timer = $DropTimer
@onready var life_timer: Timer = $LifeTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	await animation_player.animation_finished
	
	can_drop_bomb = true
	
	player = get_tree().get_first_node_in_group("player")
	
	timer.start(1 / drop_rate)
	if not timer.timeout.is_connected(_drop_bomb):
		timer.timeout.connect(_drop_bomb)
	
	life_timer.start(life_time_duration)


func _process(_delta: float) -> void:
	await _ready()
	
	if global_position.distance_to(player.global_position) > 2000:
		_on_life_timer_timeout()


func _physics_process(delta: float) -> void:
	var forward_direction = transform.x.normalized()
	global_position += forward_direction * speed * delta


func _drop_bomb():
	if not can_drop_bomb:
		return
	var dumb_bomb = dumb_bomb_scene.instantiate()
	dumb_bomb.global_position = self.global_position
	get_tree().current_scene.add_child(dumb_bomb)
	print("drop")


func _on_life_timer_timeout() -> void:
	animation_player.play_backwards("spawn")
	can_drop_bomb = false
	await animation_player.animation_finished
	queue_free()
