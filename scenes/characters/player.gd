extends CharacterBody2D


const HUMAN_SPEED = 100.0
const BAT_SPEED = 150.0
enum Form {HUMAN, BAT}
var current_form = Form.HUMAN

@onready var human_col: CollisionShape2D = $HumanCollisionShape
@onready var bat_col: CollisionShape2D = $BatCollisionShape
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var bat_occluder: LightOccluder2D = $BatOccluder
@onready var human_occluder: LightOccluder2D = $HumanOccluder


func _ready():
	# Initialize: Ensure one is disabled and the other is active
	update_form_visuals()

func _physics_process(delta):
	# 3. Listen for the swap key (e.g., "F" key mapped to "swap_form")
	if Input.is_action_just_pressed("swap_form"):
		swap_form()
	
	# Apply movement logic based on current form
	if current_form == Form.HUMAN:
		move_human(delta)
	else:
		move_bat(delta)

	move_and_slide()

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
		# Optional: Change speed or gravity here
	else:
		anim.play("bat")
		human_col.disabled = true
		human_occluder.visible = false
		bat_col.disabled = false
		bat_occluder.visible = true
		
func move_human(delta: float):
	var directoion:= Input.get_vector("left", "right", "up", "down")
	velocity = directoion * HUMAN_SPEED
	move_and_slide()
	
func move_bat(delta: float):
	var directoion:= Input.get_vector("left", "right", "up", "down")
	velocity = directoion * BAT_SPEED
	move_and_slide()
