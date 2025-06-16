extends Node2D


const tree_scene: PackedScene = preload("res://scenes/tree.tscn")

@export var amount: int = 5

var last_amount: int

var trees_on_scene = []
