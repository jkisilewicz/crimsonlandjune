# turret-bullet_power_up.gd
extends Area2D
var turret_scene = preload("res://turrets/bullet/turret_rifle.tscn")

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Stwórz nowe działko
		var turret = turret_scene.instantiate()
		
		# Ustaw pozycję działka na pozycję power-upa
		turret.global_position = global_position
		
		# Dodaj działko do głównej sceny
		get_tree().get_current_scene().add_child(turret)
		
		# Usuń power-up
		queue_free()
