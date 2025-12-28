extends StaticBody2D

@onready var col_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var notice_area: Area2D = $NoticeArea
@onready var hint: Label = $Hint
@export var effective_distance := 300
var showing_hint := false
var is_activated := false
@export var COOLDOWN_TIME := 5.0
var cooldown_timer := 0.0

func _ready() -> void:
	notice_area.body_entered.connect(_on_notice_entered)
	notice_area.body_exited.connect(_on_notice_exited)
	hide_hint()

func _physics_process(delta: float) -> void:
	if is_activated:
		if cooldown_timer >= COOLDOWN_TIME:
			deactivate()
			cooldown_timer = 0.0
		else:
			cooldown_timer += delta

func _on_notice_entered(body):
	if body.is_in_group("player"):
		body.register_interactable(self)
		show_hint()

func show_hint():
	showing_hint = true
	hint.visible = true

func _on_notice_exited(body):
	if body.is_in_group("player"):
		body.unregister_interactable(self)
		hide_hint()
		
func hide_hint():
	showing_hint = false
	hint.visible = false
	
func player_interact(player: CharacterBody2D):
		activate()

func activate():
	if not is_activated:
		is_activated = true
		Events.noise_made.emit(self)
		hide_hint()
	
func deactivate():
	is_activated =  false
