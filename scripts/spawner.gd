extends Node

func spawn_object(scene: PackedScene, position: Vector2, rotation: float = 0, parent: Node = null) -> Node:
	var instance: Node2D = scene.instantiate()
	instance.global_position = position
	instance.rotation = rotation
	if parent:
		parent.add_child(instance)
	else:
		get_tree().current_scene.add_child(instance)
	return instance
