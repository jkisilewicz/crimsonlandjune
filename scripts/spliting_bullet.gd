extends Bullet


var split_bullet_amount: int = 5

var bullet_scene: PackedScene = preload("res://scenes/spliting_bullet.tscn")

var splited_bullet: bool = false


func set_splitable_bullet(value):
	splited_bullet = true
	split_bullet_amount = value


func _split_bullet():
	print(split_bullet_amount)
	for i in range(split_bullet_amount):
		# Instantiate bullet from the scene.
		var new_bullet = bullet_scene.instantiate()
		
		# Set bullet damage
		if new_bullet.has_method("set_damage"):
			new_bullet.set_damage(self.damage)
		
		# Set bullet speed 
		if new_bullet.has_method("set_speed"):
			new_bullet.set_speed(self.speed * 0.75)
		
		# Set bullet split amount
		if new_bullet.has_method("set_splitable_bullet"):
			new_bullet.set_splitable_bullet(self.split_bullet_amount * 0.5)
		
		# Setup bullet spread to all angle.
		var deviation = deg_to_rad(randf_range(
				self.rotation - 180, self.rotation + 180
			))
		
		# Set splited bullet position and rotation
		new_bullet.global_position = self.global_position
		new_bullet.rotation = self.global_rotation + deviation
		
		get_parent().add_child(new_bullet)


func _on_body_entered(body):
	if splited_bullet:
			return
	
	if body.has_method("take_damage"):
		_split_bullet()
		body.take_damage(damage)
		
		# Spawn blood effect at collision point
		var blood_effect = blood_scene.instantiate()
		
		# Dodajemy do głównej sceny gry aby krew pozostała nawet po zniszczeniu przeciwnika
		var main_scene = get_tree().get_current_scene()
		main_scene.add_child(blood_effect)
		
		# Pozycja i inicjalizacja efektu krwi
		blood_effect.global_position = global_position
		blood_effect.initialize(rotation)
	queue_free()


func _on_body_exited(_body: Node2D) -> void:
	splited_bullet = false
