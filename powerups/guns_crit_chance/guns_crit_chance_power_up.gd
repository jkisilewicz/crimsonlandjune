# guns_crit_chance_power_up.gd
extends Area2D

@export var crit_chance_increment: float = 0.55  # Zwiększenie szansy na trafienie krytyczne o 55%

func _ready():
	# Połącz sygnał body_entered z funkcją obsługi
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Zwiększ szansę na trafienie krytyczne gracza
		body.stats["guns_crit_chance"] += crit_chance_increment
		
		# Wyświetl informację o zwiększonym crit chance
		_show_powerup_text(body)
		
		# Wyświetl informację o obecnym procencie crit chance
		print("Crit Chance zwiększony! Aktualny poziom: " + str(body.stats["guns_crit_chance"] * 100) + "%")
		
		# Usuń power-up
		queue_free()

func _show_powerup_text(player):
	# Załaduj scenę z damage_number
	var text_scene = load("res://scenes/damage_number.tscn")
	if text_scene:
		var powerup_text = text_scene.instantiate()
		
		# Ustaw tekst informujący o podniesieniu crit chance
		powerup_text.text = "Crit Chance +" + str(int(crit_chance_increment * 100)) + "% (Teraz: " + str(int(player.stats["guns_crit_chance"] * 100)) + "%)"
		
		# Zmień kolor, aby odróżnić od obrażeń
		powerup_text.modulate = Color(1.0, 0.5, 0.0)  # Pomarańczowy kolor
		
		# Pozycjonujemy tekst nad graczem
		powerup_text.position = player.global_position + Vector2(0, -70)
		
		# Dodajemy tekst do aktualnej sceny
		get_tree().get_current_scene().add_child(powerup_text)
