extends CharacterBody2D

enum State { PATROL, CHASE, SEARCH }
var current_state = State.PATROL

var player_ref: CharacterBody2D = null
var can_see_player = false

@export var patrol_path: Path2D  # Assign this in the Inspector!
var patrol_points: PackedVector2Array
var current_patrol_index = 0
@export var patrol_speed = 40.0

# SETTINGS
@export var movement_speed = 60.0
@export var stop_distance = 30.0  # How close the enemy gets before stopping

# REFERENCES
# We need to rotate this PIVOT, not the whole enemy
@onready var flashlight_pivot: Node2D = $FlashlightHolder 
@onready var vision_cone: Area2D = $FlashlightHolder/VisionCone

func _ready():
	vision_cone.body_entered.connect(_on_vision_entered)
	vision_cone.body_exited.connect(_on_vision_exited)
	# SETUP PATROL
	if patrol_path:
		# Convert the path's local points to Global positions
		# because the Enemy moves in Global space.
		for point in patrol_path.curve.get_baked_points():
			patrol_points.append(patrol_path.to_global(point))

func _physics_process(delta):
	if can_see_player and player_ref:
		check_line_of_sight()
	
	match current_state:
		State.PATROL:
			patrol_movement(delta) # <--- CALL THIS 
		State.CHASE:
			follow_player(delta)

func _on_vision_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		can_see_player = true

func _on_vision_exited(body):
	if body == player_ref:
		player_ref = null
		can_see_player = false
		current_state = State.PATROL

func check_line_of_sight():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player_ref.global_position)
	query.collision_mask = 8 
	query.exclude = [self] 
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		current_state = State.CHASE
		
	else:
		pass

func follow_player(delta):
	if player_ref:
		# --- FIX FOR PUSHING ---
		# Check distance before moving
		var dist = global_position.distance_to(player_ref.global_position)
		
		if dist > stop_distance:
			velocity = global_position.direction_to(player_ref.global_position) * movement_speed
			move_and_rotate()
		else:
			# We are close enough to attack!
			velocity = Vector2.ZERO
			# (Here you would add code to trigger an attack animation)
			
func move_and_rotate():
	# 1. Move the character using the standard engine physics
	move_and_slide()
	# 2. Update Rotation automatically based on the resulting movement
	# We check length > 0 to prevent it from snapping to 0 degrees when stopped
	if velocity.length() > 5.0:
		flashlight_pivot.rotation = velocity.angle()
		
func patrol_movement(delta):
	if patrol_points.is_empty():
		return # Do nothing if no path is assigned
		
	var target = patrol_points[current_patrol_index]
	var dist = global_position.distance_to(target)

	# 1. CHECK IF ARRIVED (Use a small threshold like 10 pixels)
	if dist < 10.0:
		# Go to next point
		current_patrol_index += 1
		
		# Loop back to 0 if we hit the end
		if current_patrol_index >= patrol_points.size():
			current_patrol_index = 0
			
	# 2. MOVE
	# We use our wrapper function to handle rotation automatically
	var direction = global_position.direction_to(target)
	velocity = direction * patrol_speed
	move_and_rotate()
