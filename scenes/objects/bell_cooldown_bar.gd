extends ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var ratio = value / max_value
	var new_color = Color.GREEN.lerp(Color.RED, ratio)
	var stylebox = get_theme_stylebox("fill")
	stylebox.bg_color = new_color
