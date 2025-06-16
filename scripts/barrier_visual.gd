@tool
extends Line2D


@export var base_width = 10


func _process(_delta: float) -> void:
	var parent_scale = get_parent().scale.x
	# Invert the scale to keep line width visually consistent
	width = base_width / parent_scale
