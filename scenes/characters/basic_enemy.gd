extends CharacterBody2D

enum State {PATROL, CHASE, STUN, SEARCH, NULL, FOLLOW_POINT}
var state = State.PATROL
const DELTA = 0.01

var player_ref: CharacterBody2D = null
var can_see_player = false

@export var patrol_path: Path2D
var patrol_points: PackedVector2Array
var current_patrol_index = 0

# SETTINGS
@export var PATROL_SPEED = 40.0
@export var MOVEMENT_SPEED = 60.0
@export var STOP_DISTANCE = 30.0

# REFERENCES
@onready var flashlight_holder: Node2D = $FlashlightHolder 
@onready var vision_cone: Area2D = $FlashlightHolder/VisionCone
@onready var nav_agent = $NavigationAgent2D

@export var ATTACK_TIME := 1.0
@export var ATTACK_POWER := 1
var attack_timer := 0.0

@export var STUN_TIME := 1.0
var stun_timer := 0.0
var prev_state = State.NULL
var prev_state_helper := State.NULL

@export var SEARCH_CYCLE_COUNT := 3
@export var SEARCH_CYCLE_TIME := 1.5
var search_count := 0
var search_timer := 0.0

@onready var emotion_icon: AnimatedSprite2D = $EmotionIcon
var emotion := "empty"
var next_emotion := "empty"
var emotion_timer := 0.0

func _ready():
	vision_cone.body_entered.connect(_on_vision_entered)
	vision_cone.body_exited.connect(_on_vision_exited)

	if patrol_path:
		for point in patrol_path.curve.get_baked_points():
			patrol_points.append(patrol_path.to_global(point))

func _physics_process(delta):
	if can_see_player and player_ref:
		check_line_of_sight()
	
	match state:
		State.PATROL:
			patrol_movement(delta)
		State.CHASE:
			follow_player(delta)
		State.STUN:
			stun(delta)
		State.SEARCH:
			search(delta)
			
	update_emotion(delta)

func _on_vision_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		can_see_player = true
		attack_timer = ATTACK_TIME

func _on_vision_exited(body):
	if body == player_ref:
		player_ref = null
		can_see_player = false
		state = State.PATROL

func check_line_of_sight():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player_ref.global_position)
	query.collision_mask = 8 
	query.exclude = [self] 
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		state = State.CHASE
		emotion = "surprise"

func follow_player(delta):
	if player_ref:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist > STOP_DISTANCE:
			nav_agent.target_position = player_ref.global_position
			var next_path_pos = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_path_pos)
			velocity = direction * MOVEMENT_SPEED
			move_and_rotate()
		else:
			velocity = Vector2.ZERO
			attack(delta)

func attack(delta: float):
	emotion = "angry"
	if abs(attack_timer - ATTACK_TIME) < DELTA:
				player_ref.update_health_amount(-1 * ATTACK_POWER)
				attack_timer = 0.0
	else:
		attack_timer += delta

func move_and_rotate():
	move_and_slide()
	if velocity.length() > 5.0:
		flashlight_holder.rotation = velocity.angle()

func patrol_movement(delta):
	if patrol_points.is_empty(): return
	emotion = "empty"
	
	var target = patrol_points[current_patrol_index]
	nav_agent.target_position = target

	if nav_agent.is_navigation_finished():
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		return

	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	velocity = direction * PATROL_SPEED
	move_and_rotate()
	
func stun(delta: float):
	if state != State.STUN:
		prev_state_helper = prev_state
		prev_state = state
		state = State.STUN
		emotion = "surprise"
		
	elif abs(stun_timer - STUN_TIME) < DELTA:
		stun_timer = 0.0
		state = prev_state
		prev_state = prev_state_helper
		emotion = "empty"
		
	stun_timer += delta
		
func search(delta: float):
	if state != State.SEARCH:
		prev_state_helper = prev_state
		prev_state = state
		state = State.SEARCH
		emotion = "question"
	elif abs(search_timer - SEARCH_CYCLE_TIME) < DELTA:
		search_timer = 0.0
		flashlight_holder.rotation += PI
		search_count += 1

	if search_count == SEARCH_CYCLE_COUNT:
		search_count = 0
		state = prev_state
		prev_state = prev_state_helper
		emotion = "empty"
		set_emotion("angry", 2.0)
		return

	search_timer += delta
	velocity = Vector2.ZERO
	
func set_emotion(name: String, time: float):
	next_emotion = emotion
	emotion = name
	emotion_timer = time
	
	
func update_emotion(delta: float):
	if next_emotion != "empty":
		if emotion_timer < DELTA:
			emotion = next_emotion
			next_emotion = "empty"
			emotion_timer = 0.0
		else:
			emotion_timer -= delta
	
	emotion_icon.play(emotion)
	
