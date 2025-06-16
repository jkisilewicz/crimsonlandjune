# guns_reload_speed_power_up.gd
extends Area2D

@export var reload_speed_increment: float = 0.9  # Zwiększenie szybkości przeładowania o 90%

func _ready():
	# Połącz sygnał body_entered z funkcją obsługi
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Zwiększ szybkość przeładowania gracza
		body.stats["guns_reload_speed"] += reload_speed_increment
		
		# Wyświetl informację o zwiększonej szybkości przeładowania
		_show_powerup_text(body)
		
		# Wyświetl informację o obecnej szybkości przeładowania
		print("Reload Speed zwiększony! Aktualny poziom: " + str(body.stats["guns_reload_speed"] * 100) + "%")
		
		# Usuń power-up
		queue_free()

func _show_powerup_text(player):
	# Załaduj scenę z damage_number
	var text_scene = load("res://scenes/damage_number.tscn")
	if text_scene:
		var powerup_text = text_scene.instantiate()
		
		# Ustaw tekst informujący o podniesieniu reload speed
		powerup_text.text = "Reload Speed +" + str(int(reload_speed_increment * 100)) + "% (Teraz: " + str(int(player.stats["guns_reload_speed"] * 100)) + "%)"
		
		# Zmień kolor, aby odróżnić od obrażeń
		powerup_text.modulate = Color(0.0, 0.7, 1.0)  # Jasnoniebieski kolor
		
		# Pozycjonujemy tekst nad graczem
		powerup_text.position = player.global_position + Vector2(0, -70)
		
		# Dodajemy tekst do aktualnej sceny
		get_tree().get_current_scene().add_child(powerup_text)
