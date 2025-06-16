# armor_power_up.gd
extends Area2D

@export var armor_increment: float = 0.55  # Zwiększenie pancerza o 55% (redukcja obrażeń)

func _ready():
	# Połącz sygnał body_entered z funkcją obsługi
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Zwiększ pancerz gracza
		body.stats["armor"] += armor_increment
		
		# Wyświetl informację o zwiększonym pancerzu
		_show_powerup_text(body)
		
		# Wyświetl informację o obecnej wartości pancerza
		print("Pancerz zwiększony! Aktualny poziom: " + str(body.stats["armor"] * 100) + "% redukcji obrażeń")
		
		# Usuń power-up
		queue_free()

func _show_powerup_text(player):
	# Załaduj scenę z damage_number
	var text_scene = load("res://scenes/damage_number.tscn")
	if text_scene:
		var powerup_text = text_scene.instantiate()
		
		# Ustaw tekst informujący o podniesieniu pancerza
		powerup_text.text = "Armor +" + str(int(armor_increment * 100)) + "% (Teraz: " + str(int(player.stats["armor"] * 100)) + "%)"
		
		# Zmień kolor na niebieski, aby odróżnić od obrażeń
		powerup_text.modulate = Color(0.2, 0.2, 1.0)  # Niebieski
		
		# Pozycjonujemy tekst nad graczem
		powerup_text.position = player.global_position + Vector2(0, -70)
		
		# Dodajemy tekst do aktualnej sceny
		get_tree().get_current_scene().add_child(powerup_text)
		
		# Dodaj efekt wizualny pancerza na postaci
		_show_armor_effect(player)

# Nowa funkcja do wyświetlania efektu pancerza
func _show_armor_effect(player):
	# Utwórz tymczasowy efekt wizualny wokół gracza
	var sprite = player.get_node("MiniLili")
	if sprite:
		# Efekt niebieskiej poświaty
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.3, 0.3, 1.0, 0.8), 0.2)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3)
