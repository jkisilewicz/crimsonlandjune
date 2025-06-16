extends Control

@warning_ignore("unused_signal")
signal stat_selected(stat_name, increment_value)

var available_stats = []
var upgrade_values = {
	"max_hp": 20.0,
	"hp_regen": 0.2,
	"guns_damage": 0.2,
	"guns_attack_speed": 0.1,
	"speed": 25.0
}

var stat_display_names = {
	"max_hp": "Max Health",
	"hp_regen": "Health Regeneration",
	"guns_damage": "Weapon Damage",
	"guns_attack_speed": "Attack Speed",
	"speed": "Movement Speed"
}

var stat_descriptions = {
	"max_hp": "Increase your maximum health points,\nallowing you to survive longer in battle.",
	"hp_regen": "Increase health regeneration rate,\nhealing more HP per second.",
	"guns_damage": "Increase damage dealt by all your weapons,\nmaking you more deadly in combat.",
	"guns_attack_speed": "Increase your weapons' firing rate,\ndealing damage faster.",
	"speed": "Increase movement speed,\nhelping you dodge attacks and reposition faster."
}

var level_counters = {
	"max_hp": 0,
	"hp_regen": 0,
	"guns_damage": 0,
	"guns_attack_speed": 0,
	"speed": 0
}

# Ścieżki do ikon dla poszczególnych statystyk
var stat_icons = {
	"max_hp": "res://images/icons/max_hp_icon.png",
	"hp_regen": "res://images/icons/hp_regen_icon.png",
	"guns_damage": "res://images/icons/guns_damage_icon.png",
	"guns_attack_speed": "res://images/icons/guns_attack_speed_icon.png",
	"speed": "res://images/icons/speed_icon.png"
}

# Referencje do paneli
var old_ui_container: Control
var advanced_panel1: Control
var advanced_panel2: Control
var advanced_panel3: Control

# Referencje do elementów UI
var texture_rect1: TextureRect
var label_title1: Label
var label_desc1: Label
var label_level1: Label

var texture_rect2: TextureRect
var label_title2: Label
var label_desc2: Label
var label_level2: Label

var texture_rect3: TextureRect
var label_title3: Label
var label_desc3: Label
var label_level3: Label

# Referencje do przycisków (nowe)
var button1: Button
var button2: Button
var button3: Button

func _ready():
	# Inicjalizacja referencji do elementów UI
	_find_ui_elements()
	
	# Podłącz obsługę kliknięć do paneli
	_connect_panel_signals()
	
	# WAŻNE: Na początku to UI powinno być ukryte
	visible = false

# Funkcja do tworzenia niewidzialnych przycisków bez efektu fokusa
func _create_invisible_button(_name):
	var button = Button.new()
	button.name = name
	button.flat = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Usuń focus border - to jest kluczowe
	button.focus_mode = Control.FOCUS_NONE
	
	# Usuń style dla wszystkich stanów przycisku
	var empty_style = StyleBoxEmpty.new()
	
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	
	return button

func _find_ui_elements():
	# Znajdź stare elementy UI
	old_ui_container = find_child("LevelUp", true)
	
	# Znajdź panele przez ich unikalne identyfikatory
	advanced_panel1 = get_node_or_null("%LevelUpAdvanced1")
	advanced_panel2 = get_node_or_null("%LevelUpAdvanced2")
	advanced_panel3 = get_node_or_null("%LevelUpAdvanced3")
	
	# Znajdź elementy UI dla pierwszego panelu
	texture_rect1 = get_node_or_null("%TextureRect1")
	label_title1 = get_node_or_null("%LabelTitle1")
	label_desc1 = get_node_or_null("%LabelDesc1")
	label_level1 = get_node_or_null("%LabelLevel1")
	
	# Znajdź elementy UI dla drugiego panelu
	texture_rect2 = get_node_or_null("%TextureRect2")
	label_title2 = get_node_or_null("%LabelTitle2")
	label_desc2 = get_node_or_null("%LabelDesc2")
	label_level2 = get_node_or_null("%LabelLevel2")
	
	# Znajdź elementy UI dla trzeciego panelu
	texture_rect3 = get_node_or_null("%TextureRect3")
	label_title3 = get_node_or_null("%LabelTitle3")
	label_desc3 = get_node_or_null("%LabelDesc3")
	label_level3 = get_node_or_null("%LabelLevel3")
	
	# Dodaj przyciski do każdego panelu z odpowiednim rozmiarem
	if advanced_panel1:
		# Usuń istniejący przycisk, jeśli istnieje (zapobiega duplikatom przy ponownym załadowaniu)
		var existing_button = advanced_panel1.get_node_or_null("ClickButton1")
		if existing_button:
			existing_button.queue_free()
			
		button1 = _create_invisible_button("ClickButton1")
		advanced_panel1.add_child(button1)
		button1.pressed.connect(func(): _select_stat(0))
		
	# Powtórz dla paneli 2 i 3
	if advanced_panel2:
		var existing_button = advanced_panel2.get_node_or_null("ClickButton2")
		if existing_button:
			existing_button.queue_free()
			
		button2 = _create_invisible_button("ClickButton2")
		advanced_panel2.add_child(button2)
		button2.pressed.connect(func(): _select_stat(1))
		
	if advanced_panel3:
		var existing_button = advanced_panel3.get_node_or_null("ClickButton3")
		if existing_button:
			existing_button.queue_free()
			
		button3 = _create_invisible_button("ClickButton3")
		advanced_panel3.add_child(button3)
		button3.pressed.connect(func(): _select_stat(2))

func _connect_panel_signals():
	# Podłącz obsługę kliknięć do paneli advanced
	if advanced_panel1:
		if not advanced_panel1.gui_input.is_connected(_on_panel1_gui_input):
			advanced_panel1.gui_input.connect(_on_panel1_gui_input)
	
	if advanced_panel2:
		if not advanced_panel2.gui_input.is_connected(_on_panel2_gui_input):
			advanced_panel2.gui_input.connect(_on_panel2_gui_input)
	
	if advanced_panel3:
		if not advanced_panel3.gui_input.is_connected(_on_panel3_gui_input):
			advanced_panel3.gui_input.connect(_on_panel3_gui_input)

func _update_panel_contents():
	# Ukryj stare elementy UI
	if old_ui_container:
		old_ui_container.visible = false
	
	# PANEL 1
	if advanced_panel1 and 0 < available_stats.size():
		var stat_name = available_stats[0]
		var display_name = stat_display_names[stat_name]
		var description = stat_descriptions[stat_name]
		var level = level_counters[stat_name]
		
		# Załaduj teksturę właściwą dla danej statystyki
		if texture_rect1:
			var icon_path = stat_icons[stat_name]
			if ResourceLoader.exists(icon_path):
				texture_rect1.texture = load(icon_path)
		
		if label_title1:
			label_title1.text = display_name + " +" + str(upgrade_values[stat_name])
		if label_desc1:
			label_desc1.text = description
		if label_level1:
			label_level1.text = "Level " + str(level + 1)  # Dodajemy 1, aby pokazywać Level 1 zamiast Level 0
		
		advanced_panel1.visible = true
	elif advanced_panel1:
		advanced_panel1.visible = false
	
	# PANEL 2
	if advanced_panel2 and 1 < available_stats.size():
		var stat_name = available_stats[1]
		var display_name = stat_display_names[stat_name]
		var description = stat_descriptions[stat_name]
		var level = level_counters[stat_name]
		
		# Załaduj teksturę właściwą dla danej statystyki
		if texture_rect2:
			var icon_path = stat_icons[stat_name]
			if ResourceLoader.exists(icon_path):
				texture_rect2.texture = load(icon_path)
		
		if label_title2:
			label_title2.text = display_name + " +" + str(upgrade_values[stat_name])
		if label_desc2:
			label_desc2.text = description
		if label_level2:
			label_level2.text = "Level " + str(level + 1)  # Dodajemy 1, aby pokazywać Level 1 zamiast Level 0
		
		advanced_panel2.visible = true
	elif advanced_panel2:
		advanced_panel2.visible = false
	
	# PANEL 3
	if advanced_panel3 and 2 < available_stats.size():
		var stat_name = available_stats[2]
		var display_name = stat_display_names[stat_name]
		var description = stat_descriptions[stat_name]
		var level = level_counters[stat_name]
		
		# Załaduj teksturę właściwą dla danej statystyki
		if texture_rect3:
			var icon_path = stat_icons[stat_name]
			if ResourceLoader.exists(icon_path):
				texture_rect3.texture = load(icon_path)
		
		if label_title3:
			label_title3.text = display_name + " +" + str(upgrade_values[stat_name])
		if label_desc3:
			label_desc3.text = description
		if label_level3:
			label_level3.text = "Level " + str(level + 1)  # Dodajemy 1, aby pokazywać Level 1 zamiast Level 0
		
		advanced_panel3.visible = true
	elif advanced_panel3:
		advanced_panel3.visible = false

# Funkcja do pokazania UI przy level up
func show_level_up():
	# Zaktualizuj zawartość paneli
	_update_panel_contents()
	
	# Pokazujemy UI
	visible = true
	
	# Dopiero teraz pauzujemy grę
	get_tree().paused = true

func set_available_stats(stat_list):
	available_stats = stat_list
	_update_panel_contents()

# Obsługa kliknięć na panelach
func _on_panel1_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_stat(0)

func _on_panel2_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_stat(1)

func _on_panel3_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_stat(2)

func _select_stat(index):
	if index < available_stats.size():
		var selected_stat = available_stats[index]
		
		# Zwiększ licznik poziomu danego statystyka
		level_counters[selected_stat] += 1
		
		# Emituj sygnał o wybranym statystyce
		emit_signal("stat_selected", selected_stat, upgrade_values[selected_stat])
		
		# Ukrywamy UI
		visible = false
		
		# Odpauzowujemy grę
		get_tree().paused = false
