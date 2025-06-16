# bombs_power_up.gd
extends Area2D

var bomb_scene = preload("res://support_weapons/bombs/bombs.tscn")
var total_duration = 14.0  # Czas trwania zrzucania bomb w sekundach
var spawn_interval = 2.0   # Interwał między bombami w sekundach
var is_active = false      # Flaga oznaczająca czy power-up jest aktywny

# Timery
var duration_timer
var spawn_timer

func _ready():
	# Połącz sygnał body_entered z naszą funkcją
	body_entered.connect(_on_body_entered)
	
	# Stwórz timer dla całkowitego czasu trwania
	duration_timer = Timer.new()
	duration_timer.one_shot = true
	duration_timer.wait_time = total_duration
	duration_timer.timeout.connect(_on_duration_timeout)
	add_child(duration_timer)
	
	# Stwórz timer dla interwału zrzucania bomb
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_bomb)
	add_child(spawn_timer)

func _on_body_entered(body):
	# Sprawdzamy, czy obiekt, który wszedł w obszar, należy do grupy "player"
	if body.is_in_group("player") and not is_active:
		# Aktywuj zdolność zrzucania bomb
		is_active = true
		start_bombing()
		
		# Ukryj power-up (zamiast usuwać, żeby timery mogły dalej działać)
		visible = false
		
		# Wyłącz kolizję
		$CollisionShape2D.set_deferred("disabled", true)

func start_bombing():
	# Uruchom timery
	duration_timer.start()
	spawn_timer.start()
	
	# Natychmiast zrzuć pierwszą bombę
	_spawn_bomb()

func _on_duration_timeout():
	# Zakończ zrzucanie bomb
	spawn_timer.stop()
	is_active = false
	
	# Teraz możemy usunąć power-up
	queue_free()

func _spawn_bomb():
	if not is_active:
		return
	
	# Znajdź gracza
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Pobierz pozycję gracza
	var player_position = player.global_position
	
	# Losuj pozycję bomby
	var offset_x = randf_range(-550, 550)
	var offset_y = randf_range(-450, 450)
	var bomb_position = Vector2(
		player_position.x + offset_x,
		player_position.y + offset_y
	)
	
	# Sprawdź, czy bomba jest za blisko gracza (mniej niż 200 pikseli)
	var distance_to_player = bomb_position.distance_to(player_position)
	
	# Jeśli bomba jest za blisko, przesuń ją na granicę strefy bezpieczeństwa
	if distance_to_player < 250:
		# Oblicz kierunek od gracza do bomby
		var direction = (bomb_position - player_position).normalized()
		
		# Ustaw pozycję bomby dokładnie 200 pikseli od gracza w tym samym kierunku
		bomb_position = player_position + (direction * 250)
	
	# Instancjuj nową bombę
	var bomb = bomb_scene.instantiate()
	
	# Dodaj bombę do głównej sceny
	get_tree().get_current_scene().add_child(bomb)
	
	# Ustaw pozycję bomby
	bomb.global_position = bomb_position
