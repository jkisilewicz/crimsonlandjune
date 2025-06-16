extends Area2D

@export var slow_duration: float = 10.0
@export var cooldown_duration: float = 60.0
@export var slow_factor: float = 0.3
@export var music_slow_factor: float = 0.8
@export var ease_duration: float = 1.0  # How fast it fades in/out

var active = false

@onready var vignette_effect: TextureRect = $CanvasLayer/TextureRect


func _ready():
	Powerups.powerups_pool.erase("res://powerups/time_slow_down/time_slowdown_powerup.tscn")
	
	connect("body_entered", _on_body_entered)


func _on_body_entered(body: Node2D):
	if active:
		return
	
	if body.is_in_group("player"):
		active = true
		$Sprite2D.hide()
		set_monitoring(false)
		_start_slowmo_effect()


func _start_slowmo_effect():
	# Gradually lower time scale
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(Engine, "time_scale", slow_factor, ease_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(MusicController, "pitch_scale", music_slow_factor, ease_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(vignette_effect, "modulate", Color.WHITE, ease_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Wait for duration, then tween back
	await get_tree().create_timer(slow_duration, false, false, true).timeout
	
	var tween_back = create_tween()
	tween_back.set_parallel(true)
	tween_back.tween_property(Engine, "time_scale", 1.0, ease_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_back.tween_property(MusicController, "pitch_scale", 1.0, ease_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_back.tween_property(vignette_effect, "modulate", Color.TRANSPARENT, ease_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Wait for cooldown to loop back
	await get_tree().create_timer(cooldown_duration).timeout
	_start_slowmo_effect()
