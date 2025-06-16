class_name Player
extends CharacterBody2D

@onready var health_progress_bar: ProgressBar = %HealthProgressBar
@onready var force_fields: Array[TextureProgressBar] = [%ForceField1, %ForceField2]
@onready var game_over = %GameOver
@onready var actual_weapon_ui: TextureRect = %ActualWeapon
@onready var hud: Control = $CanvasLayer/Hud
@onready var health_text_label: Label = $CanvasLayer/Hud/WeaponHealth/HealthLabel
@onready var xp_progress_bar: ProgressBar = %XPProgressBar
@onready var mini_lili = $MiniLili

var level_up_ui_scene = preload("res://scenes/ui/level_up_ui.tscn")
#var upgradable_stats = ["guns_damage"]
var upgradable_stats = ["max_hp", "hp_regen", "guns_damage", "guns_attack_speed", "speed"]

var stats := {
	"max_hp": 100.0,                 # JEST POWERUP 
	"hp_regen": 0.5,                 # JEST POWERUP 
	"guns_damage": 1.0,              # JEST POWERUP 
	"guns_attack_speed": 1.0,        # JEST POWERUP szybkostrzelność
	"speed": 450.0,                  # JEST POWERUP 
	
	"guns_crit_chance": 0.05,        # JEST POWERUP guns_crit_chance (0.05 = 5%)
	"guns_reload_speed": 1.0,        # JEST POWERUP (do poprawy)
	"guns_range": 1.0,
	"dodge": 0.00,                   # JEST POWERUP szansa na unik (np. 0.01 = 1%)
	"armor": 0.00,                   # JEST POWERUP procent redukcji obrażeń (np. 0.01 = 1%)
	
	"xp_multiplier": 1.0,            # mnożnik zdobywanego doświadczenia
	
	"turret_power": 1.0,             # siła wieżyczek
	"turret_max_hp": 1.0,            #
	"turret_hp_regen": 1.0,          # 
	
	"friend_damage": 1.0,            # mnożnik obrażeń zadawanych przez ewentualne dodatkowe postacie pomagające graczowi
	"friend_hp_regen": 0.0,          # 
	"friend_max_hp": 0.0,            # 
	"friend_speed": 0.0,             #
	
	"boss_health_reduction": 0.0,    # zmniejszenie % liczby hp bossów
	"boss_speed_reduction": 0.0,     # 
	
	"resurrection_number": 0.0,      #
	
	"passive_income": 0.0,           # passive income in base buildings
}

var current_hp: float

var is_force_field_activated: bool = false
var force_field_recharge_time: float = 30.0
var force_field_timer: float = 0.0

# Dodaj zmienną doświadczenia
var xp: int = 0

var level: int = 1

var level_xp_requirements := [
	0, 1000, 3000, 6000, 10000, 15000, 21000, 28000, 36000, 45000,
	55000, 66000, 78000, 91000, 105000, 120000, 136000, 153000, 171000,
	190000, 210000, 231000, 253000, 276000, 300000, 325000, 351000, 378000,
	406000, 435000, 465000, 496000, 528000, 561000, 595000, 630000, 666000,
	703000, 741000, 780000, 820000, 861000, 903000, 946000, 990000, 1035000,
	1081000, 1128000, 1176000, 1225000
]

var current_weapon: Node = null

func update_health_ui():
	health_progress_bar.value = current_hp
	health_text_label.text = str(int(current_hp))

func _ready():
	current_hp = stats["max_hp"]
	health_progress_bar.max_value = stats["max_hp"]
	update_health_ui()

	add_to_group("player")
	#game_over.hide()

	get_node("CanvasLayer/Hud/PlayerInfoBox/Level").update_level(level)
	equip_weapon("pistol")
	
	for force_field in force_fields:
		force_field.max_value = force_field_recharge_time


func _process(delta: float) -> void:
	if is_force_field_activated:
		_update_force_field(delta)


func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * stats["speed"]
	move_and_slide()

	if velocity.x != 0:
		$MiniLili.scale.x = -1 if velocity.x < 0 else 1
		
	if velocity.length() > 0:
		mini_lili.play_walk_animation()
	else:
		mini_lili.play_idle_animation()
	regenerate_hp(delta)


func equip_weapon(weapon_type: String) -> void:
	# clear current weapon
	if $Weapon.get_children() != null:
		for child in $Weapon.get_children():
			child.queue_free()

	print(weapon_type)

	var new_weapon
	var _weapon_texture_path = ""
	match weapon_type:
		"pistol":
			new_weapon = WeaponScenes.pistol_scene.instantiate()
			#actual_weapon_ui.texture = load("res://images/guns_power_ups/pistol_power_up.png")
		"shotgun":
			new_weapon = WeaponScenes.shotgun_scene.instantiate()
			actual_weapon_ui.texture = load("res://images/guns_power_ups/shotgun_power_up.jpg")
		"shotgun_fire":
			new_weapon = WeaponScenes.shotgun_fire_scene.instantiate()
			actual_weapon_ui.texture = load("res://weapons/shotgun_fire/shotgun-fire.png")
		"rifle":
			new_weapon = WeaponScenes.rifle_scene.instantiate()
			actual_weapon_ui.texture = load("res://images/guns_power_ups/rifle_power_up.jpg")
		"laser_gun":
			new_weapon = WeaponScenes.laser_gun_scene.instantiate()
		"plasma_gun":
			new_weapon = WeaponScenes.plasma_gun_scene.instantiate()
		"minigun":
			new_weapon = WeaponScenes.minigun_scene.instantiate()
		"railgun":
			new_weapon = WeaponScenes.railgun_scene.instantiate()
		"rocket_launcher":
			new_weapon = WeaponScenes.rocket_launcher_scene.instantiate()
		"laser_shotgun":
			new_weapon = WeaponScenes.laser_shotgun_scene.instantiate()
		"grenade_launcher":
			new_weapon = WeaponScenes.grenade_launcher_scene.instantiate()
		"laser_minigun":
			new_weapon = WeaponScenes.laser_minigun_scene.instantiate()
		"plasma_minigun":
			new_weapon = WeaponScenes.plasma_minigun_scene.instantiate()
		"plasma_shotgun":
			new_weapon = WeaponScenes.plasma_shotgun_scene.instantiate()
		"flamethrower":
			new_weapon = WeaponScenes.flamethrower.instantiate()
		"gas_gun":
			new_weapon = WeaponScenes.gas_gun.instantiate()
		"wave_rifle":
			new_weapon = WeaponScenes.wave_rifle.instantiate()
		"spliting_bullet_gun":
			new_weapon = WeaponScenes.spliting_bullet_gun.instantiate()
		"laser_beamer":
			new_weapon = WeaponScenes.laser_beamer.instantiate()
		"the_maul_gun":
			new_weapon = WeaponScenes.the_maul.instantiate()
		"rainbow_beamer":
			new_weapon = WeaponScenes.rainbow_beamer.instantiate()
		"electric_weapon":
			new_weapon = WeaponScenes.electric_weapon.instantiate()
		"missile_launcher":
			new_weapon = WeaponScenes.missile_launcher.instantiate()
		"money_gun":
			new_weapon = WeaponScenes.money_gun.instantiate()
		_:
			return

	$Weapon.add_child(new_weapon)
	new_weapon.position = Vector2.ZERO
	current_weapon = new_weapon


func activate_force_field():
	is_force_field_activated = true
	$ForceField.visible = true

func _update_force_field(delta):
	if force_field_timer < force_field_recharge_time:
		force_field_timer += delta
		$ForceField.modulate = Color(Color.WHITE, 0.25)
	else:
		$ForceField.modulate = Color(Color.WHITE, 1)
	
	for force_field in force_fields:
		force_field.value = move_toward(
				force_field.value, 
				force_field_timer, 
				force_field_recharge_time * 2 * delta
		)

func _is_force_field_up() -> bool:
	if force_field_timer >= force_field_recharge_time:
		return true
	return false

func gain_experience(amount: int) -> void:
	xp += amount
	print("Zdobyto", amount, "XP. Aktualne XP:", xp)
	check_level_up()
	update_xp_ui()

func check_level_up() -> void:
	while level < level_xp_requirements.size() and xp >= level_xp_requirements[level]:
		level_up()

func update_xp_ui():
	var xp_for_this_level = xp - level_xp_requirements[level - 1]
	var xp_needed_for_next_level = level_xp_requirements[level] - level_xp_requirements[level - 1]
	xp_progress_bar.value = xp_for_this_level
	xp_progress_bar.max_value = xp_needed_for_next_level

func level_up() -> void:
	level += 1
	var level_label = get_node("CanvasLayer/Hud/PlayerInfoBox/Level")
	if level_label:
		level_label.update_level(level)
	show_level_up_options()

func show_level_up_options() -> void:
	hud.hide()
	
	var level_up_ui = %LevelUp
	if level_up_ui:
		var available_stats = select_random_stats(upgradable_stats, 3)
		level_up_ui.set_available_stats(available_stats)
		if not level_up_ui.is_connected("stat_selected", Callable(self, "_on_stat_selected")):
			level_up_ui.connect("stat_selected", Callable(self, "_on_stat_selected"))
		level_up_ui.show_level_up()
	else:
		print("BŁĄD: Nie znaleziono węzła LevelUp w ścieżce $Hud/LevelUp")

func select_random_stats(stat_list: Array, count: int) -> Array:
	var available = stat_list.duplicate()
	var result = []
	available.shuffle()
	for i in range(min(count, available.size())):
		result.append(available[i])
	return result

func _on_stat_selected(stat_name: String, increment_value: float) -> void:
	hud.show()
	
	stats[stat_name] += increment_value
	if stat_name == "max_hp":
		current_hp += increment_value
		health_progress_bar.max_value = stats["max_hp"]
		update_health_ui()
	
	print("Increased " + stat_name + " by " + str(increment_value) + ". New value: " + str(stats[stat_name]))

func regenerate_hp(delta: float) -> void:
	if current_hp < stats["max_hp"]:
		current_hp += stats["hp_regen"] * delta 
		if current_hp > stats["max_hp"]:
			current_hp = stats["max_hp"]
		update_health_ui()

func apply_damage(amount: float) -> void:
	if _is_force_field_up():
		force_field_timer = 0.0
		return
	
	var rand_val = randi() % 100 / 100.0 
	if rand_val < stats["dodge"]:
		print("Uniknięto ataku! (Dodge) - Szansa wynosiła: " + str(stats["dodge"] * 100) + "%")
		# Dodaj efekt wizualny uniku
		_show_dodge_effect()
		return  
	
	amount = amount * (1.0 - stats["armor"])
	current_hp -= amount
	current_hp = max(0, current_hp)
	update_health_ui()

	if current_hp <= 0:
		game_over.show()
		get_tree().paused = true

# Nowa funkcja do wyświetlania efektu uniku
func _show_dodge_effect():
	# Załaduj scenę z damage_number
	var text_scene = load("res://scenes/damage_number.tscn")
	if text_scene:
		var dodge_text = text_scene.instantiate()
		
		# Ustaw tekst "DODGE!"
		dodge_text.text = "DODGE!"
		
		# Ustaw kolor (np. zielony dla uniku)
		dodge_text.modulate = Color(0.2, 1.0, 0.2)  # Jasnozielony
		
		# Pozycjonujemy tekst nad graczem
		dodge_text.position = global_position + Vector2(0, -70)
		
		# Dodajemy tekst do aktualnej sceny
		get_tree().get_current_scene().add_child(dodge_text)
	
	# Możesz także dodać efekt wizualny na samej postaci
	# Na przykład, krótkotrwałe miganie lub zmianę koloru
	var sprite = $MiniLili
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.3, 1.0, 0.3, 0.8), 0.1)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.2)
