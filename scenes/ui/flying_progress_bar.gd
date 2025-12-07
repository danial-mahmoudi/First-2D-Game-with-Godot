extends ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(_delta):
	# 1. Calculate the ratio (0.0 is empty, 1.0 is full)
	var ratio = value / max_value
	
	# 2. Blend the color
	# lerp() blends two colors based on the ratio.
	# If ratio is 0, it's Green. If ratio is 1, it's Red.
	var new_color = Color.RED.lerp(Color.GREEN, ratio)
	
	# 3. Apply the color to the StyleBox
	# We get the 'fill' stylebox we created earlier and change its background color
	var stylebox = get_theme_stylebox("fill")
	stylebox.bg_color = new_color


func _on_player_fly_point_changed(new_value: Variant) -> void:
	value = new_value
