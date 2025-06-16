# range_power_up.gd
extends Area2D

@export var range_multiplier: float = 1.2  # Możliwość edycji w Inspectorze

func _ready():
	# Używamy składni do łączenia sygnału w Godot 4.3
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# Upewnij się, że power-up reaguje tylko na gracza
	if body.is_in_group("player"):
		print("Range power-up odebrany, multiplier =", range_multiplier)
		
		# Zwiększamy zasięg broni gracza
		body.stats["guns_range"] *= range_multiplier
		
		# Aktualizujemy zasięg aktualnie wyposażonej broni
		if body.current_weapon and body.current_weapon.has_method("update_weapon_range"):
			body.current_weapon.update_weapon_range()
		
		# Efekt wizualny (opcjonalnie)
		spawn_pickup_effect()
		
		# Usuwamy power-up
		queue_free()

func spawn_pickup_effect():
	# Tutaj możesz dodać efekt wizualny podniesienia power-upa
	# Na przykład animację, dźwięk, lub cząsteczki
	pass
