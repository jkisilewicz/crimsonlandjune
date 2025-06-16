# damage_power_up.gd
extends Area2D

@export var damage_multiplier: float = 1.2  # Możliwość edycji w Inspectorze

func _ready():
	# Używamy nowej składni do łączenia sygnału w Godot 4.3
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# Upewnij się, że power-up reaguje tylko na gracza
	if body.is_in_group("player"):
		print("Damage power-up odebrany, multiplier =", damage_multiplier)
		body.stats["guns_damage"] *= damage_multiplier
		queue_free()
