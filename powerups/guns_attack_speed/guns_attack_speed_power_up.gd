#guns_attack_speed_power_up.gd
extends Area2D

@export var attack_speed_multiplier: float = 1.2  # Możliwość edycji w Inspectorze

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Sprawdź, czy obiekt jest graczem
	if body.is_in_group("player"):
		# Modyfikacja statystyk gracza
		body.stats["guns_attack_speed"] *= attack_speed_multiplier

		# Usunięcie power-upa po użyciu
		queue_free()
