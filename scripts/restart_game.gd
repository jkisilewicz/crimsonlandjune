extends Label

# Stałe dla animacji
const HOVER_SCALE = 1.2
const ANIMATION_DURATION = 0.2  # Czas trwania animacji w sekundach

# Ustaw pivot (punkt obrotu/skalowania) na środek
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Ustaw punkt pivotu na środek
	pivot_offset = size / 2

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		reset_game()

func reset_game():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_mouse_entered():
	# Płynna animacja powiększania i zmiany koloru
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), ANIMATION_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 0), ANIMATION_DURATION)

func _on_mouse_exited():
	# Płynna animacja powrotu do normalnego rozmiaru i koloru
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1, 1), ANIMATION_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1), ANIMATION_DURATION)
