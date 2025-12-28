extends CharacterBody2D

const DELTA = 0.01

@export var MAX_HUMAN_SPEED := 120.0
@export var MIN_HUMAN_SPEED := 30.0
@export var MAX_BAT_SPEED := 180.0
@export var MIN_BAT_SPEED := 100.0
@export var BAR_USE_SPEED := 20.0
@export var BAR_IDLE_SPEED := 6.0
@export var BAR_LOAD_SPEED := 6.0
@export var is_invinsible := true
@export var MAX_HEALTH := 6
@export var DAMAGE_PER_SECOND := 1

enum Form {HUMAN, BAT}
var current_form = Form.HUMAN

var is_moving := false
var is_taking_hit := false
var is_in_any_light := false

var light_point := 0.0 # between 0 and 100
var fly_point := 100.0 # between 0 and 100
var health_point := MAX_HEALTH
var damage_timer := 0.0

var current_interactable_object: StaticBody2D = null

@onready var human_col: CollisionShape2D = $HumanCollisionShape
@onready var bat_col: CollisionShape2D = $BatCollisionShape
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var bat_occluder: LightOccluder2D = $BatOccluder
@onready var human_occluder: LightOccluder2D = $HumanOccluder

signal fly_point_changed(new_value)
signal light_point_changed(new_value)
signal health_point_changed(new_value)


func _ready():
	update_form_visuals()

func _physics_process(delta):
	if Input.is_action_just_pressed("swap_form"):
		swap_form()
		
	if Input.is_action_just_pressed("interact"):
		interact()
	
	if current_form == Form.HUMAN:
		move_human(delta)
		
	else:
		move_bat(delta)
	
	update_light_meter(delta)
	update_fly_meter(delta)
	update_health_meter(delta)

func swap_form():
	if current_form == Form.HUMAN:
		if not is_in_any_light: current_form = Form.BAT
	else:
		current_form = Form.HUMAN
	
	update_form_visuals()

func update_form_visuals():
	if current_form == Form.HUMAN:
		anim.play("human")
		human_col.disabled = false
		human_occluder.visible = true
		bat_col.disabled = true
		bat_occluder.visible = false
		set_collision_mask_value(1, true)
		set_collision_mask_value(2, true)
		
	else:
		anim.play("bat")
		human_col.disabled = true
		human_occluder.visible = false
		bat_col.disabled = false
		bat_occluder.visible = true
		set_collision_mask_value(1, true)
		set_collision_mask_value(2, false)
		
func interact():
	if current_interactable_object != null and current_interactable_object.has_method("player_interact"):
		current_interactable_object.player_interact(self)
		
func register_interactable(node: Node2D):
	current_interactable_object = node

func unregister_interactable(node: Node2D):
	if current_interactable_object == node:
		current_interactable_object = null

func move_human(_delta: float):
	var directoion:= Input.get_vector("left", "right", "up", "down")  
	velocity = directoion * (MIN_HUMAN_SPEED + (MAX_HUMAN_SPEED - MIN_HUMAN_SPEED) * (1 - light_point/100.0))
	if directoion != Vector2(0,0):
		is_moving = true;
	else:
		is_moving = false;
	move_and_slide()
	
func update_light_meter(delta: float):
	var total_exposure_amount = 0.0
	is_in_any_light = false
	
	if current_form == Form.BAT:
		update_light_amount(-1 * BAR_LOAD_SPEED * delta)
		return
		
	# 1. Get all lights in the level
	var all_lights = get_tree().get_nodes_in_group("light")
	var space_state = get_world_2d().direct_space_state
	
	for light in all_lights:
		# 2. DISTANCE CHECK (Optimization)
		# Don't bother raycasting if the light is miles away
		var distance = global_position.distance_to(light.global_position)
		if distance > light.radius:
			continue
			
		# 3. RAYCAST CHECK (Line of Sight)
		# Create a ray from Light -> Player
		var query = PhysicsRayQueryParameters2D.create(light.global_position, global_position)
		
		# IMPORTANT: Only collide with Layer 1 (Walls)
		# If we hit nothing, the path is clear.
		query.collision_mask = 8 # layer 4, the shadow casters
		
		var result = space_state.intersect_ray(query)
		
		if result.is_empty():
			# The ray hit nothing, so we have a clear line of sight!
			is_in_any_light = true
			
			# Calculate intensity based on distance (Closer = fills faster)
			# Formula: (1 - (dist / radius)) * light_power
			var falloff = 1.0 - (distance / light.radius)
			total_exposure_amount += light.intensity_per_second * falloff
			

	# 4. Update the Bar
	if is_in_any_light:
		update_light_amount(total_exposure_amount * delta)
		
		
	else:
		# Optional: Slowly decrease bar when in shadow?
		update_light_amount(-1 * BAR_LOAD_SPEED * delta)
			
func update_light_amount(amount:float):
	light_point += amount
	light_point = clamp(light_point, 0, 100)
	light_point_changed.emit(light_point)
	
func move_bat(_delta: float):
	var directoion:= Input.get_vector("left", "right", "up", "down")
	if directoion != Vector2(0,0):
		is_moving = true;
	else:
		is_moving = false;
	velocity = directoion * (MIN_BAT_SPEED + (MAX_BAT_SPEED - MIN_BAT_SPEED) * fly_point / 100.0)
	move_and_slide()
	
func update_fly_meter(delta: float):
	if fly_point == 0 and current_form == Form.BAT:
		swap_form()
	if current_form == Form.HUMAN:
		update_fly_amount(BAR_LOAD_SPEED * delta)
	elif is_moving :
		update_fly_amount(-1 * BAR_USE_SPEED * delta)
	else:
		update_fly_amount(-1 * BAR_IDLE_SPEED * delta)
	
	
func update_fly_amount(amount: float):
	fly_point += amount
	fly_point = clamp(fly_point, 0, 100)
	fly_point_changed.emit(fly_point)
	
func update_health_meter(delta: float):
	if abs(DAMAGE_PER_SECOND - damage_timer) < DELTA:
		update_health_amount(-1)
		damage_timer = 0.0
	if abs(100.0 - light_point) < DELTA:
		damage_timer += delta
	if health_point == 0 and not is_invinsible:
		kill_and_respawn()
	
func update_health_amount(amount: int):
	health_point += amount
	health_point = clamp(health_point, 0, MAX_HEALTH)
	health_point_changed.emit(health_point)
	
func kill_and_respawn():
	var spawn_point = $"../SpawnPoint"
	light_point = 0.0
	fly_point = 100.0
	health_point = MAX_HEALTH
	
	current_form = Form.HUMAN
	update_form_visuals()
	global_position = spawn_point.global_position
