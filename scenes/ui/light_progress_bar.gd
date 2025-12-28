extends ProgressBar



func _ready() -> void:
	pass


func _physics_process(_delta: float) -> void:
	var ratio = value / max_value
	var new_color = Color.GREEN.lerp(Color.RED, ratio)
	var stylebox = get_theme_stylebox("fill")
	stylebox.bg_color = new_color


func _on_player_light_point_changed(new_value: Variant) -> void:
	value = new_value
