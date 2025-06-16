# drone_power_up.gd
extends Area2D

# Upewnij się, że ścieżka do sceny drona jest poprawna
var drone_scene = preload("res://friends/drone/drone.tscn")
# Odległość, w jakiej ma się pojawić dron od gracza
@export var spawn_distance: float = 300.0

func _ready():
	# Połącz sygnał body_entered z funkcją _on_body_entered
	# Użycie Callable jest bardziej nowoczesne w Godot 4
	body_entered.connect(Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# Sprawdź, czy obiekt, który wszedł, jest w grupie "player"
	if body.is_in_group("player"):
		# Sprawdź, czy scena drona została poprawnie załadowana
		if not drone_scene:
			print("BŁĄD: Scena drona nie została załadowana w drone_power_up.gd!")
			return # Zakończ funkcję, jeśli nie ma sceny

		# Stwórz instancję drona
		var drone = drone_scene.instantiate()
		if not drone:
			print("BŁĄD: Nie udało się utworzyć instancji drona w drone_power_up.gd!")
			return # Zakończ funkcję, jeśli instancja się nie powiodła

		# Oblicz losowy kierunek jako wektor jednostkowy
		var random_angle = randf_range(0, TAU) # TAU to stała równa 2 * PI
		var offset_direction = Vector2.RIGHT.rotated(random_angle) # Zaczynamy od (1,0) i obracamy losowo

		# Oblicz wektor przesunięcia o żądaną długość
		var spawn_offset = offset_direction * spawn_distance

		# Ustaw początkową globalną pozycję drona
		# Pozycja gracza + obliczone przesunięcie
		drone.global_position = body.global_position + spawn_offset

		# Dodaj drona do głównej sceny
		# Można rozważyć dodanie go do innego węzła (np. kontenera na "przyjaciół")
		# get_tree().get_current_scene().add_child(drone)
		# Lepsze może być dodanie do rodzica power-upa, jeśli jest to np. główna scena gry
		var parent_node = get_parent()
		if parent_node:
			parent_node.add_child(drone)
		else:
			# Fallback, jeśli power-up nie ma rodzica
			get_tree().get_root().add_child(drone)
			print("OSTRZEŻENIE: drone_power_up nie ma rodzica, dron dodany do roota.")


		# Opcjonalnie: Przypisz gracza do drona, jeśli dron ma taką zmienną
		if drone.has_method("set_player_reference"):
			drone.set_player_reference(body)
		elif "player" in drone: # Jeśli ma publiczną zmienną 'player'
			drone.player = body


		print("Stworzono drona w pozycji {drone.global_position} (offset: {spawn_offset})")

		# Usuń power-up po jego zebraniu
		queue_free()
