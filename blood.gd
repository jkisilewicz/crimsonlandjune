#blood.gd
extends Node2D
@onready var dynamic_particles = $DynamicParticles
var blood_textures = []
var creation_time = 0.0

func _ready():
	creation_time = Time.get_ticks_msec() / 1000.0	
	# Konfiguracja dynamicznych cząstek
	dynamic_particles.emitting = true
	dynamic_particles.gravity = Vector2(0, 0)
	dynamic_particles.direction = Vector2(0, 0)
	dynamic_particles.spread = 180.0
	dynamic_particles.one_shot = true
	
	# Podłączanie sygnału
	if not dynamic_particles.is_connected("finished", Callable(self, "_on_dynamic_particles_finished")):
		dynamic_particles.connect("finished", Callable(self, "_on_dynamic_particles_finished"))
	
	# Dodaj węzeł do grupy
	add_to_group("blood_stain")

# Funkcja do inicjalizacji efektu krwi z kierunkiem pocisku
func initialize(bullet_rotation):
	# Ustawienie kierunku dynamicznych cząstek
	var direction = Vector2(cos(bullet_rotation), sin(bullet_rotation))
	dynamic_particles.direction = direction
	dynamic_particles.spread = 30.0
	dynamic_particles.emitting = true
	
	# Tworzenie statycznych plam krwi
	create_blood_splats(direction, bullet_rotation)

# Funkcja tworząca plamy krwi jako Sprite'y
func create_blood_splats(direction, _bullet_rotation):
	if blood_textures.size() == 0:
		return
	
	# Liczba plam do wygenerowania
	var splat_count = randi_range(3, 6)
	
	for i in range(splat_count):
		var blood_splat = Sprite2D.new()
		
		# Wybierz losową teksturę z dostępnych
		var texture_index = randi() % blood_textures.size()
		blood_splat.texture = blood_textures[texture_index]
		
		# Ustaw losową pozycję
		var distance = randf_range(5, 20)
		var angle_variation = randf_range(-PI/4, PI/4)
		var splat_direction = direction.rotated(angle_variation)
		var offset = splat_direction * distance
		blood_splat.position = offset
		
		# Losowa rotacja
		blood_splat.rotation = randf_range(0, 2 * PI)
		
		# Losowa skala
		var scale_factor = randf_range(0.3, 1.0)
		blood_splat.scale = Vector2(scale_factor, scale_factor)
		
		# Losowa modulacja koloru
		var r = randf_range(0.7, 1.0)
		var g = randf_range(0.0, 0.2)
		var b = randf_range(0.0, 0.2)
		var a = randf_range(0.7, 1.0)
		blood_splat.modulate = Color(r, g, b, a)
		
		blood_splat.z_index = 0
		
		# Dodaj do sceny
		add_child(blood_splat)

func _on_dynamic_particles_finished():
	# Usuwamy tylko węzeł dynamicznych cząstek
	dynamic_particles.queue_free()

func create_blood_at_position(world_position):
	var mouse_pos = world_position
	
	# Sprawdź czy mamy tekstury
	if blood_textures.size() == 0:
		return
		
	# Stwórz pojedynczą, dużą plamę krwi
	var blood_splat = Sprite2D.new()
	
	# Wybierz losową teksturę z dostępnych
	var texture_index = randi() % blood_textures.size()
	blood_splat.texture = blood_textures[texture_index]
		
	# Ustaw globalną pozycję plamy (względem świata)
	blood_splat.global_position = mouse_pos
	
	# Duża skala dla lepszej widoczności
	blood_splat.scale = Vector2(3.0, 3.0)
	
	# Jaskrawy kolor dla lepszej widoczności
	blood_splat.modulate = Color(1, 0, 0, 1)  # Jaskrawa czerwień
	
	# Najwyższy z-index aby być nad wszystkim
	blood_splat.z_index = 0
	
	# Dodaj do sceny
	get_parent().add_child(blood_splat)
