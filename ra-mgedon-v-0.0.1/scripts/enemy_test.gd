extends CharacterBody2D

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var hp=100
var direction
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	move_and_slide()
	if not is_on_floor():
		velocity.y += gravity * delta
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(hp)
	if hp <=0:
		queue_free()
	if velocity.x>0:
		velocity.x-=16
	elif velocity.x<0:
		velocity.x+=16

func take_damage(damage):
	hp-=damage
	
