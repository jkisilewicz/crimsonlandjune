#hp_regen_power_up.gd
extends Area2D

@export var hp_regen_increase_amount: float = 0.1  # Możliwość edycji w Inspectorze

func _ready():
	print("HP Regen Power-up initialized with increase amount: ", hp_regen_increase_amount)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("Body entered HP Regen Power-up area: ", body.name)
	
	if body.is_in_group("player"):
		# Zapisz starą wartość regeneracji do debugowania
		var old_regen_value = body.stats["hp_regen"]
		
		# Zwiększenie regeneracji HP gracza
		body.stats["hp_regen"] += hp_regen_increase_amount
		
		# Wyświetl informacje debugowania
		print("HP Regen Power-up collected by player!")
		print("Old regen value: ", old_regen_value, " HP/s")
		print("New regen value: ", body.stats["hp_regen"], " HP/s")
		print("Increase: +", hp_regen_increase_amount, " HP/s")
		
		# Nie ma potrzeby aktualizacji UI bezpośrednio jak w przypadku max_hp,
		# ponieważ regeneracja jest stosowana automatycznie w funkcji regenerate_hp
		
		queue_free()
