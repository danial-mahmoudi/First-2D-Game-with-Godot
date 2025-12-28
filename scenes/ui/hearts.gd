extends HBoxContainer

@export var hearts : Array[TextureRect]

func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_health_point_changed(new_value: Variant) -> void:
	var value = new_value
	var counter := 0
	while counter < hearts.size():
		if value >= 2:
			value -= 2
			hearts[counter].texture = load("res://assets/art/ui/stat_bar/full-heart.png")
		elif value == 1:
			value -= 1
			hearts[counter].texture = load("res://assets/art/ui/stat_bar/half-hurt.png")
		else:
			hearts[counter].texture = load("res://assets/art/ui/stat_bar/empty-hurt.png")
		counter += 1
	
