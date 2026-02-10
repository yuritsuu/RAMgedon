extends CharacterBody2D

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var hp := 100
var can_take_dmg := true

@onready var timer: Timer = $Timer
@onready var hurtbox_colision: CollisionShape2D = $hurtbox/hurtbox_colision


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	# wygaszanie knockbacku X
	velocity.x = move_toward(velocity.x, 0, 1200 * delta)



func _process(delta: float) -> void:
	print(hp)
	if hp <= 0:
		queue_free()
	if not can_take_dmg:
		hurtbox_colision.disabled=true
	else:
		hurtbox_colision.disabled=false


func take_damage(damage: int):
	if not can_take_dmg:
		return

	hp -= damage
	can_take_dmg = false
	timer.start()


func apply_knockback(force: Vector2):
	velocity += force


func _on_timer_timeout() -> void:
	can_take_dmg = true
