extends Beamer


@onready var cpu_particles_2d_2: CPUParticles2D = $WeaponPivot/Pistol/LaserRay/CPUParticles2D2


func _process(delta: float) -> void:
	super(delta)
	
	if laser_ray.is_colliding():
		cpu_particles_2d_2.global_position = laser_ray.get_collision_point()
