#golem.gd
extends CharacterBody2D

@onready var player: CharacterBody2D = $"../Player"
@onready var damage_timer: Timer = $DamageTimer
@onready var hit_area: Area2D = $HitArea
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hurt_timer: Timer = $HurtTimer 
@onready var round_enemy_body: Sprite2D = %RoundEnemyBody

var health: int = 100
const DAMAGE_RATE = 4.0
const EXPERIENCE_REWARD = 50
var is_hurt = false

# Zmienna do przechowywania aktualnego celu ataku
var current_target = null

func _ready():
	# Dodaj golema do grupy enemy, aby drony mogły go wykrywać
	add_to_group("enemy")
	
	if not has_node("HurtTimer"):
		hurt_timer = Timer.new()
		hurt_timer.name = "HurtTimer"
		hurt_timer.one_shot = true
		hurt_timer.wait_time = 0.5  # Dostosuj do długości animacji hurt
		add_child(hurt_timer)
	
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	play_walk()
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	hit_area.body_exited.connect(_on_hit_area_body_exited)
	damage_timer.timeout.connect(_on_damage_timer_timeout)

func _physics_process(_delta):
	# Znajdź najbliższy cel (gracz lub przyjaciel)
	var target = player
	var alliance = get_tree().get_nodes_in_group("alliance")
	
	if alliance.size() > 0:
		var player_distance = global_position.distance_to(player.global_position)
		for ally in alliance:
			if is_instance_valid(ally):
				var ally_distance = global_position.distance_to(ally.global_position)
				if ally_distance < player_distance:
					target = ally
					player_distance = ally_distance
	
	# Ustaw aktualny cel
	current_target = target
	
	# Poruszaj się w kierunku celu
	var direction = global_position.direction_to(current_target.global_position)
	velocity = direction * 200.0
	
	if direction.x < 0:
		%RoundEnemyBody.flip_h = true  # Facing left
	else:
		%RoundEnemyBody.flip_h = false  # Facing right
	
	move_and_slide()

func take_damage(amount):
	health -= amount
	_show_damage(amount)
	
	if not is_hurt:
		is_hurt = true
		$HitSound.play()
		animation_player.stop() 
		animation_player.play("hurt")
		hurt_timer.start() 
	
	if health <= 0:
		if player.has_method("gain_experience"):
			player.gain_experience(EXPERIENCE_REWARD)
		if get_tree().current_scene.has_method("spawn_power_up"):
			get_tree().current_scene.spawn_power_up(global_position)
		const SMOKE_SCENE = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_SCENE.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		queue_free()

func _show_damage(amount):
	var damage_number_scene = preload("res://scenes/damage_number.tscn")
	var damage_label = damage_number_scene.instantiate()
	damage_label.text = str(amount)
	damage_label.position = global_position + Vector2(0, -50)
	get_tree().get_current_scene().add_child(damage_label)

func _on_hurt_timer_timeout():
	is_hurt = false
	if animation_player.current_animation == "hurt":
		play_walk()

func _on_hit_area_body_entered(body):
	if body == player:
		current_target = player
		damage_timer.start()
		print("Golem: Kolizja z graczem - start zadawania obrażeń")
	elif body.is_in_group("alliance"):
		current_target = body
		damage_timer.start()
		print("Golem: Kolizja z przyjacielem - start zadawania obrażeń")

func _on_hit_area_body_exited(body):
	if body == current_target:
		damage_timer.stop()
		current_target = null
		print("Golem: Wyjście z obszaru - stop zadawania obrażeń")

func _on_damage_timer_timeout():
	if current_target and is_instance_valid(current_target):
		if current_target == player:
			player.apply_damage(DAMAGE_RATE)
		elif current_target.has_method("take_damage"):
			current_target.take_damage(DAMAGE_RATE)
		
func play_walk():
	animation_player.play("walk")

func play_hurt():
	is_hurt = true
	animation_player.play("hurt")
	hurt_timer.start()
