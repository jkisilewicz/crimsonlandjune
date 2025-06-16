extends Area2D


var on_screen_time: float = 10
var spawn_delay_time: float = 40

var electric_drone: PackedScene = preload("res://support_weapons/electric_drone/electric_drone.tscn")

var current_electric_drone: Node

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var next_spawn: Timer = $NextSpawn
@onready var on_screen_timer: Timer = $OnScreen



func _spawn_drone():
	if on_screen_timer.is_stopped():
		current_electric_drone = Spawner.spawn_object(electric_drone, Vector2.ZERO, 0, self)
		on_screen_timer.start(on_screen_time)


func _on_screen_timeout() -> void:
	print("TIMEOUT LIL NIGGA")
	current_electric_drone.queue_free()
	next_spawn.start(spawn_delay_time)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	var drone = Spawner.spawn_object(electric_drone, Vector2.ZERO, 0, self)
	current_electric_drone = drone
	on_screen_timer.start(on_screen_time)
	
	collision_shape_2d.set_deferred("disabled", true)
	sprite_2d.hide()
	
	get_parent().call_deferred("remove_child", self)
	body.call_deferred("add_child", self)
	
	position = Vector2.ZERO
