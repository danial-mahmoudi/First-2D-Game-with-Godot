extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.noise_made.connect(_on_noise_made)

func _on_noise_made(node: StaticBody2D):
	print("noise activated at ", node.global_position)
	alert_nearest_enemy(node.global_position, node.effective_distance)
	
func alert_nearest_enemy(origin: Vector2, distance: float):
	pass
