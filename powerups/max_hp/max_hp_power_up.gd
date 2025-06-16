#hp_power_up.gd
extends Area2D

@export var hp_increase_amount: float = 5.0  # Możliwość edycji w Inspectorze

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Zwiększenie maksymalnego HP gracza
		body.stats["max_hp"] += hp_increase_amount
		
		# Aktualizacja UI i wartości związanych ze zdrowiem
		body.health_progress_bar.max_value = body.stats["max_hp"]
		body.current_hp += hp_increase_amount  # Zwiększenie aktualnego HP o tę samą wartość
		body.update_health_ui()
		queue_free()
