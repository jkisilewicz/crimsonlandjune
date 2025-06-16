# dodge_power_up.gd
extends Area2D

@export var dodge_increment: float = 0.55  # Zwiększenie szansy uniku o 55%

func _ready():
	# Połącz sygnał body_entered z funkcją obsługi
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Zwiększ szansę na unik gracza
		body.stats["dodge"] += dodge_increment
		
		print("Dodge zwiększony! Aktualny poziom: " + str(body.stats["dodge"] * 100) + "%")
		
		# Wyświetl informację o zwiększonym dodge
		_show_powerup_text(body)
		
		# Usuń power-up
		queue_free()

func _show_powerup_text(player):
	# Załaduj scenę z damage_number (lub możesz utworzyć nową dedykowaną scenę)
	var text_scene = load("res://scenes/damage_number.tscn")
	if text_scene:
		var powerup_text = text_scene.instantiate()
		
		# Ustaw tekst informujący o podniesieniu dodge
		powerup_text.text = "Dodge +" + str(int(dodge_increment * 100)) + "%"
		
		# Możesz zmienić kolor, aby odróżnić od obrażeń
		powerup_text.modulate = Color(0.5, 0.8, 1.0)  # Jasnoniebieski kolor
		
		# Pozycjonujemy tekst nad graczem
		powerup_text.position = player.global_position + Vector2(0, -70)
		
		# Dodajemy tekst do aktualnej sceny
		get_tree().get_current_scene().add_child(powerup_text)
