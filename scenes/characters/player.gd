extends CharacterBody2D


const HUMAN_SPEED = 100.0
const BAT_SPEED = 150.0
const BAR_USE_SPEED = 20.0
const BAR_LOAD_SPEED = 6.0
enum Form {HUMAN, BAT}
var current_form = Form.HUMAN
var is_moving = false

var light_point = 0.0
var fly_point = 100

@onready var human_col: CollisionShape2D = $HumanCollisionShape
@onready var bat_col: CollisionShape2D = $BatCollisionShape
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var bat_occluder: LightOccluder2D = $BatOccluder
@onready var human_occluder: LightOccluder2D = $HumanOccluder

signal fly_point_changed(new_value)


func _ready():
	# Initialize: Ensure one is disabled and the other is active
	update_form_visuals()

func _physics_process(delta):
	# Listen for the swap key (e.g., "F" key mapped to "swap_form")
	if Input.is_action_just_pressed("swap_form"):
		swap_form()
	
	# Apply movement logic based on current form
	if current_form == Form.HUMAN:
		move_human(delta)
		
	else:
		move_bat(delta)
	
	update_light_meter(delta)
	update_fly_meter(delta)

func swap_form():
	# Toggle the state
	if current_form == Form.HUMAN:
		current_form = Form.BAT
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
		
func move_human(_delta: float):
	var directoion:= Input.get_vector("left", "right", "up", "down")  
	velocity = directoion * HUMAN_SPEED
	if directoion != Vector2(0,0):
		is_moving = true;
	else:
		is_moving = false;
	move_and_slide()
	
func update_light_meter(delta: float):
	#TODO
	pass
	
func move_bat(_delta: float):
	var directoion:= Input.get_vector("left", "right", "up", "down")
	if directoion != Vector2(0,0):
		is_moving = true;
	else:
		is_moving = false;
	velocity = directoion * BAT_SPEED
	move_and_slide()
	
func update_fly_meter(delta: float):
	if fly_point == 0 and current_form == Form.BAT:
		swap_form()
	if current_form == Form.HUMAN:
		fly_point += BAR_LOAD_SPEED * delta
	elif is_moving :
		fly_point -= BAR_USE_SPEED * delta
		if fly_point < 0.0:
			fly_point = 0.0
	
	fly_point_changed.emit(fly_point)
	
	
	
