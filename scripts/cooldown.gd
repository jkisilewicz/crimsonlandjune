class_name Cooldown
extends Node


var _timer: float = 0.0


func _process(delta: float) -> void:
	if _timer > 0:
		_timer -= delta


func is_ready() -> bool:
	return _timer <= 0


func trigger(cooldown_time: float):
	_timer = cooldown_time
