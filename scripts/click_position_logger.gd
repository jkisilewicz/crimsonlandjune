extends Node2D

# Zmienne do przechowywania pozycji kliknięć
var click_positions = []
const MAX_POINTS = 20  # Maksymalna liczba zapamiętanych kliknięć

func _ready():
	print("Logger pozycji myszy aktywny. Kliknij w dowolnym miejscu, aby zobaczyć współrzędne.")

func _input(event):
	# Sprawdź czy jest to zdarzenie kliknięcia lewym przyciskiem myszy
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Pobierz globalną pozycję myszy
		var mouse_pos = get_global_mouse_position()
		print("Kliknięto w pozycji: ", mouse_pos)
		
		# Dodaj pozycję do listy
		click_positions.append(mouse_pos)
		if click_positions.size() > MAX_POINTS:
			click_positions.remove_at(0)
		
		# Wymusza ponowne rysowanie
		queue_redraw()

# Funkcja rysująca punkty w miejscach kliknięć
func _draw():
	for pos in click_positions:
		draw_circle(to_local(pos), 5, Color(0, 1, 0, 0.5))  # Zielone kółko w miejscu kliknięcia
