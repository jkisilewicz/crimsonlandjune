extends Node2D


@export var damage: int = 10
@export var rotation_speed: float = 90  # drones rotation in deg/sec

var is_active: bool = false

@onready var drones: Array[Area2D] = [$Drone, $Drone2, $Drone3, $Drone4]


func _enter_tree() -> void:
	hide()


func _process(delta: float) -> void:
	for drone in drones:
		drone.monitoring = is_active
	
	if is_active:
		rotation_degrees += rotation_speed * delta


func _on_drone_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemy"):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
