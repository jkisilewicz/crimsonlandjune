extends Bullet


@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var line_2d: Line2D = $Line2D

var has_hit: bool = false


func _ready() -> void:
	speed = 0


func _process(_delta: float) -> void:
	if ray_cast_2d.is_colliding() and not has_hit:
		var body = ray_cast_2d.get_collider()
		var local_collision_point = to_local(ray_cast_2d.get_collision_point())
		
		line_2d.set_point_position(1, local_collision_point)
		
		if body == null:
			return
		
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
			has_hit = true
			
			# Spawn blood effect at collision point
			var blood_effect = blood_scene.instantiate()
			
			# Dodajemy do głównej sceny gry aby krew pozostała nawet po zniszczeniu przeciwnika
			var main_scene = get_tree().get_current_scene()
			main_scene.add_child(blood_effect)
			
			# Pozycja i inicjalizacja efektu krwi
			blood_effect.global_position = global_position
			blood_effect.initialize(rotation)
	
	await get_tree().create_timer(0.05).timeout
	
	queue_free()
