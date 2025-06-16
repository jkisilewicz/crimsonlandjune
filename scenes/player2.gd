#player.gd
extends CharacterBody2D

@onready var health_progress_bar: ProgressBar = %HealthProgressBar
@onready var game_over = %GameOver
@onready var shooting_start: Marker2D = %ShootingStart
@onready var actual_weapon_ui: TextureRect = get_node("/root/screen/Player/Hud/WeaponHealth/Frame/ActualWeapon")
@onready var health_text_label: Label = $Hud/WeaponHealth/HealthProgressBar/HealthText 
@onready var xp_progress_bar: ProgressBar = %XPProgressBar
@onready var mini_lili = $MiniLili

var pistol_scene = preload("res://weapons/pistol/pistol.tscn")
var shotgun_scene = preload("res://weapons/shotgun/shotgun.tscn")
var shotgun_fire_scene = preload("res://weapons/shotgun_fire/shotgun_fire.tscn")
var minigun_scene = preload("res://weapons/minigun/minigun.tscn")
var railgun_scene = preload("res://weapons/railgun/railgun.tscn")
var rocket_launcher_scene = preload("res://weapons/rocket_launcher/rocket_launcher.tscn")
var rifle_scene = preload("res://weapons/rifle/rifle.tscn")
var laser_gun_scene = preload("res://weapons/lasergun/laser_gun.tscn")
var laser_shotgun_scene = preload("res://weapons/laser_shotgun/laser_shotgun.tscn")
var grenade_launcher_scene = preload("res://weapons/grenade_launcher/grenade_launcher.tscn")
var laser_minigun_scene = preload("res://weapons/laser_minigun/laser_minigun.tscn")
var plasma_minigun_scene = preload("res://weapons/plasma_minigun/plasma_minigun.tscn")
var plasma_shotgun_scene = preload("res://weapons/plasma_shotgun/plasma_shotgun.tscn")
var plasma_gun_scene = preload("res://weapons/plasmagun/plasma_gun.tscn")
var level_up_ui_scene = preload("res://scenes/ui/level_up_ui.tscn")
var upgradable_stats = ["max_hp", "hp_regen", "guns_damage", "guns_attack_speed", "speed"]

var stats := {
	"max_hp": 100.0,                 # JEST POWERUP 
	"hp_regen": 0.5,                 # JEST POWERUP 
	"guns_damage": 1.0,              # JEST POWERUP 
	"guns_attack_speed": 1.0,        # JEST POWERUP 
	"guns_range": 1.0,               #!!!!!!!!!!!!!!!!!!!!!!!!
	
	"guns_bullet_speed": 1.0,        #!!!!!!!!!!!!!!!!!!!!!!!!
	"guns_crit_chance": 0.1,         #!!!!!!!!!!!!!!!!!!!!!!!!
	"guns_reload_speed": 1.0,        #!!!!!!!!!!!!!!!!!!!!!!!!
	"ammo_size_plus_one": 1.0,       # dodaje 1 pocisk więcej w magazynku !!!!!!!!!!!!!!!!!!!!!     
	"speed": 450.0,                  # JEST POWERUP 
	
	"shotgun_projectile_count": 1.0, # liczba pocisków wystrzeliwanych jednocześnie (np. dla broni typu shotgun)!!!!!!!!!!!!!!!!!!!!!!!!!!!
	"dodge": 0.00,                    # szansa na unik (np. 0.01 = 1%)
	"armor": 0.00,                    # procent redukcji obrażeń (np. 0.01 = 1%)
	"cooldown_reduction": 0.00,       # skrócenie cooldownów (np. 0.01 = 1% szybciej)
	"harvesting_range": 1.0,         # zasięg zbierania  
	
	"xp_multiplier": 1.0,            # mnożnik zdobywanego doświadczenia
	"turret_power": 1.0,             # siła wieżyczek
	"friend_damage": 1.0,            # mnożnik obrażeń zadawanych przez ewentualne dodatkowe postacie pomagające graczowi
	"friend_health": 0.0,            # ilość dodatkowego zdrowia u ewentualnych dodatkowych postaci
	"enemy_spawn_reduction": 0.0,    # zmniejszenie liczby pojawiających się wrogów
	"enemy_slowdown_aura": 0.0,      # aura spowalniająca wrogów w pobliżu
}

# Aktualne zdrowie gracza (wartość zmienna)
var current_hp: float

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
	game_over.hide()

	get_node("Hud/PlayerInfoBox/Level").update_level(level)
	equip_weapon("pistol")


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
	for child in $Weapon.get_children():
		child.queue_free()

	var new_weapon
	var weapon_texture_path = ""
	match weapon_type:
		"pistol":
			new_weapon = pistol_scene.instantiate()
			actual_weapon_ui.texture = load("res://images/guns_power_ups/pistol_power_up.png")
		"shotgun":
			new_weapon = shotgun_scene.instantiate()
			actual_weapon_ui.texture = load("res://images/guns_power_ups/shotgun_power_up.jpg")
		"shotgun_fire":
			new_weapon = shotgun_fire_scene.instantiate()
			actual_weapon_ui.texture = load("res://weapons/shotgun_fire/shotgun-fire.png")
		"rifle":
			new_weapon = rifle_scene.instantiate()
			actual_weapon_ui.texture = load("res://images/guns_power_ups/rifle_power_up.jpg")
		"laser_gun":
			new_weapon = laser_gun_scene.instantiate()
		"plasma_gun":
			new_weapon = plasma_gun_scene.instantiate()
		"minigun":
			new_weapon = minigun_scene.instantiate()
		"railgun":
			new_weapon = railgun_scene.instantiate()
		"rocket_launcher":
			new_weapon = rocket_launcher_scene.instantiate()
		"laser_shotgun":
			new_weapon = laser_shotgun_scene.instantiate()
		"grenade_launcher":
			new_weapon = grenade_launcher_scene.instantiate()
		"laser_minigun":
			new_weapon = laser_minigun_scene.instantiate()
		"plasma_minigun":
			new_weapon = plasma_minigun_scene.instantiate()
		"plasma_shotgun":
			new_weapon = plasma_shotgun_scene.instantiate()
		_:
			return

	$Weapon.add_child(new_weapon)
	new_weapon.position = Vector2.ZERO
	current_weapon = new_weapon


func gain_experience(amount: int) -> void:
	xp += amount
	#print("Zdobyto", amount, "XP. Aktualne XP:", xp)
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
	var level_label = get_node("Hud/PlayerInfoBox/Level")
	if level_label:
		level_label.update_level(level)
	show_level_up_options()

func show_level_up_options() -> void:
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
	var rand_val = randi() % 100 / 100.0 
	if rand_val < stats["dodge"]:
		print("Uniknięto ataku! (Dodge)")
		return  
	amount = amount * (1.0 - stats["armor"])
	current_hp -= amount
	current_hp = max(0, current_hp)
	update_health_ui()
	print("Zdrowie gracza:", current_hp)

	if current_hp <= 0:
		game_over.show()
		get_tree().paused = true
