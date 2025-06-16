extends Label

var move_duration: float = 0.3   # Czas trwania ruchu do docelowej pozycji (szybko)
var wait_duration: float = 0.5   # Czas, przez który etykieta pozostaje na docelowej pozycji przed rozpoczęciem zanikania
var fade_duration: float = 1.5   # Czas trwania zanikania (dłuższe wyświetlanie)

func _ready():
	# Jeśli tekst nie jest pusty, przekształcamy go na wartość całkowitą, aby nie wyświetlał części dziesiętnych
	if text.strip_edges() != "":
		text = str(int(round(text.to_float())))
	
	# Dodaj losowy offset startowy, aby numery nie zaczynały dokładnie w tym samym miejscu
	position += Vector2(randf_range(-30, 30), randf_range(-35, 35))
	
	# Oblicz docelową pozycję z losowym przesunięciem w górę i w bok
	var random_y_offset = randf_range(120, 120)
	var random_x_offset = randf_range(-120, 120)
	var target_position = position + Vector2(random_x_offset, -random_y_offset)
	
	# Utwórz tween, który najpierw szybko przesunie etykietę do target_position,
	# następnie odczeka określony czas, po czym stopniowo zmniejszy przezroczystość
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(wait_duration)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(Callable(self, "_on_tween_finished"))

func _on_tween_finished() -> void:
	queue_free()
