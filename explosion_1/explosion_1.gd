extends Node2D

func _ready():
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("explode")
		$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	queue_free()
