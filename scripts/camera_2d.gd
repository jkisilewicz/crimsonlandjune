#camera_2d
extends Camera2D

@export var extra_limit := 100

@onready var bottom_barrier: CollisionShape2D = %BottomBarrier
@onready var top_barrier: CollisionShape2D = %TopBarrier
@onready var right_barrier: CollisionShape2D = %RightBarrier
@onready var left_barrier: CollisionShape2D = %LeftBarrier


func _process(_delta: float) -> void:
	@warning_ignore("incompatible_ternary")
	limit_bottom = (bottom_barrier.global_position.y + extra_limit 
			if bottom_barrier
			else 10000000)
	@warning_ignore("incompatible_ternary")
	limit_top = (top_barrier.global_position.y - extra_limit 
			if top_barrier
			else -10000000)
	@warning_ignore("incompatible_ternary")
	limit_right = (right_barrier.global_position.x + extra_limit 
			if right_barrier
			else 10000000)
	@warning_ignore("incompatible_ternary")
	limit_left = (left_barrier.global_position.x - extra_limit 
			if left_barrier
			else -10000000)
