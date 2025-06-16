# rifle_gun.gd
extends Area2D

func _ready():
	# Połącz sygnał body_entered z naszą funkcją
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Sprawdzamy, czy obiekt, który wszedł w obszar, należy do grupy "player"
	if body.is_in_group("player"):
		# Zmieniamy broń gracza na rifle
		body.equip_weapon("minigun")
		# Usuwamy power-up z poziomu
	queue_free()
