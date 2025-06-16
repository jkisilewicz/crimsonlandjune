extends Area2D

@export var damage: int = 10
@export var tick_interval: float = 0.2

var _damage_timer := 0.0
var is_active: bool = false

@onready var damaging_collider: CollisionShape2D = $DamagingCollider
@onready var pickup_collider: CollisionShape2D = $PickupCollider
@onready var damaging_visual: Sprite2D = $DamagingVisual
@onready var pickup_visual: Sprite2D = $PickupVisual


func _ready() -> void:
	Powerups.powerups_pool.erase("res://powerups/offensive_force_field.tscn")
	
	damaging_collider.disabled = true
	pickup_collider.disabled = false
	pickup_visual.show()
	damaging_visual.hide()


func _process(delta: float) -> void:
	if not is_active:
		return
	
	_damage_timer -= delta
	if _damage_timer <= 0.0:
		_damage_timer = tick_interval * randf_range(0.8, 1.2)
		_apply_damage_to_enemies()


func _apply_damage_to_enemies() -> void:
	for body in get_overlapping_bodies():
		var random_body = get_overlapping_bodies().pick_random()
		if random_body.is_in_group("enemy") and random_body.has_method("take_damage"):
			random_body.take_damage(damage)


func _activate_powerup(body: Node2D):
	if body.is_in_group("player"):
		position = Vector2.ZERO
		get_parent().remove_child(self)
		body.add_child(self)
		
		pickup_collider.queue_free()
		pickup_visual.queue_free()
		
		damaging_collider.set_deferred("disabled", false)
		damaging_visual.show()
		
		set_collision_mask_value(1, false)
		set_collision_mask_value(2, true)
		
		is_active = true
