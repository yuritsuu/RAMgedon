extends CharacterBody2D

# ======================
# ENUMY FSM
# ======================
enum MovementState {
	IDLE,
	RUN,
	JUMP,
	DOUBLE_JUMP,
	FALL,
	WALL_SLIDE
}

enum ActionState {
	NONE,
	DASH,
	ATTACK
}

enum AttackDirection {
	FORWARD,
	UP,
	DOWN
}

var attack_dir: AttackDirection = AttackDirection.FORWARD
var move_state: MovementState = MovementState.IDLE
var action_state: ActionState = ActionState.NONE

# ======================
# RUCH
# ======================
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DOUBLE_JUMP_VELOCITY = -380.0
var facing_dir := 1

var can_double_jump := true
var is_wall_jumping := false

# ======================
# GRAWITACJA
# ======================
const BASE_GRAVITY = 1000.0
const FALL_GRAVITY_MULT = 2.5
const MAX_FALL_SPEED = 1100.0
const JUMP_CUT_MULT = 0.4

# ======================
# COYOTE + BUFFER
# ======================
const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

# ======================
# DASH
# ======================
const DASH_SPEED = 900.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 1.0

var dash_timer := 0.0
var dash_dir := Vector2.ZERO
var can_dash := true

# ======================
# WALL
# ======================
const WALL_SLIDE_SPEED = 120.0
const WALL_JUMP_FORCE = Vector2(200, -450)
const WALL_JUMP_LOCK_TIME = 0.15
var wall_jump_lock_timer := 0.0

# ======================
# ATTACK
# ======================
const ATTACK_TIME = 0.2
var attack_timer := 0.0
@onready var attack_hitbox: Area2D = $attack_hitbox
@onready var range: CollisionShape2D = $attack_hitbox/Range
@onready var health_bar: ProgressBar = $CanvasLayer/HealtBar

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D




# ======================
# MAIN LOOP
# ======================
func _physics_process(delta):
	# KONTAKT ZE ŚCIANĄ RESETUJE KONTEKST POWIETRZA
	if is_on_wall():
		can_double_jump = true
		is_wall_jumping = false
	print(PlayerStats.HP)
	handle_timers(delta)
	handle_action_fsm(delta)

	if action_state == ActionState.NONE:
		handle_movement_fsm(delta)
	
	move_and_slide()
	update_animation()


# ======================
# TIMERY
# ======================
func handle_timers(delta):
	coyote_timer -= delta
	jump_buffer_timer -= delta
	wall_jump_lock_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME


# ======================
# ACTION FSM (PRIORYTET)
# ======================
func handle_action_fsm(delta):
	match action_state:
		ActionState.DASH:
			update_dash(delta)
		ActionState.ATTACK:
			update_attack(delta)
		ActionState.NONE:
			check_action_input()


func check_action_input():
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()
	elif Input.is_action_just_pressed("attack"):
		# ustaw kierunek ataku w zależności od inputu
		if Input.is_action_pressed("up"):
			attack_dir = AttackDirection.UP
		elif Input.is_action_pressed("down"):
			attack_dir = AttackDirection.DOWN
		else:
			attack_dir = AttackDirection.FORWARD 
		start_attack()



# ======================
# DASH
# ======================
func start_dash():
	action_state = ActionState.DASH
	dash_timer = DASH_TIME
	dash_dir = Vector2(facing_dir, 0)
	can_dash = false
	

func update_dash(delta):
	dash_timer -= delta
	velocity.x = dash_dir.x * DASH_SPEED
	velocity.y = 0

	if dash_timer <= 0:
		action_state = ActionState.NONE


# ======================
# ATTACK
# ======================
func start_attack():
	action_state = ActionState.ATTACK
	attack_timer = ATTACK_TIME
	attack_hitbox.monitoring = true
	
	
	match attack_dir:
		AttackDirection.FORWARD:
			attack_hitbox.position = Vector2(24 * facing_dir, -1)
			range.shape.extents = Vector2(16, 12)
		AttackDirection.UP:
			attack_hitbox.position = Vector2(0, -24)
			range.shape.extents = Vector2(12, 16)
		AttackDirection.DOWN:
			attack_hitbox.position = Vector2(0, 20)
			range.shape.extents = Vector2(12, 16)



func update_attack(delta):
	attack_timer -= delta
	if attack_timer <= 0:
		attack_hitbox.monitoring = false
		action_state = ActionState.NONE
		$attack_hitbox/Sprite2D.hide()

func _on_attack_hitbox_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(10)
		match attack_dir:
			AttackDirection.FORWARD:
				body.velocity.x = facing_dir * 200
			AttackDirection.UP:
				body.velocity.y = -300
			AttackDirection.DOWN:
				body.velocity.y = 300



# ======================
# MOVEMENT FSM
# ======================
func handle_movement_fsm(delta):
	apply_gravity(delta)
	handle_wall_jump()
	handle_jump()
	handle_horizontal()
	handle_wall_slide()
	update_movement_state()


# ======================
# GRAWITACJA
# ======================
func apply_gravity(delta):
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y += BASE_GRAVITY * delta
		else:
			velocity.y += BASE_GRAVITY * FALL_GRAVITY_MULT * delta
			velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		coyote_timer = COYOTE_TIME
		can_double_jump = true
		can_dash = true
		is_wall_jumping = false


# ======================
# SKOK / DOUBLE JUMP
# ======================
func handle_jump():
	# WALL JUMP MA ABSOLUTNY PRIORYTET
	if is_on_wall() and not is_on_floor():
		return

	# normalny skok
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

	# skracanie skoku
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULT

	# DOUBLE JUMP (TYLKO W POWIETRZU I NIE PRZY ŚCIANIE)
	if jump_buffer_timer > 0 and not is_on_floor() and can_double_jump and velocity.y > 0:
		velocity.y = DOUBLE_JUMP_VELOCITY
		can_double_jump = false
		is_wall_jumping = false   # <<< KLUCZOWA LINIA
		jump_buffer_timer = 0



# ======================
# WALL JUMP
# ======================
func handle_wall_jump():
	if wall_jump_lock_timer > 0:
		return

	if is_on_wall() and not is_on_floor() and Input.is_action_just_pressed("jump"):
		var n = get_wall_normal()
		velocity.x = n.x * WALL_JUMP_FORCE.x
		velocity.y = WALL_JUMP_FORCE.y
		facing_dir = -sign(n.x)

		is_wall_jumping = true
		can_double_jump = true
		wall_jump_lock_timer = WALL_JUMP_LOCK_TIME


# ======================
# RUCH POZIOMY
# ======================
func handle_horizontal():
	if wall_jump_lock_timer > 0:
		return

	var dir := Input.get_axis("left", "right")
	if dir != 0:
		velocity.x = dir * SPEED
		facing_dir = sign(dir)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


# ======================
# WALL SLIDE
# ======================
func handle_wall_slide():
	if not is_on_floor() and is_on_wall() and velocity.y > 0:
		is_wall_jumping = false
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)


# ======================
# MOVEMENT STATE
# ======================
func update_movement_state():
	if not is_on_floor():
		if is_on_wall() and velocity.y > 0:
			move_state = MovementState.WALL_SLIDE
		elif is_wall_jumping:
			move_state = MovementState.JUMP
		elif velocity.y < 0:
			move_state = MovementState.DOUBLE_JUMP if not can_double_jump else MovementState.JUMP
		else:
			move_state = MovementState.FALL
	else:
		move_state = MovementState.RUN if abs(velocity.x) > 10 else MovementState.IDLE


# ======================
# ANIMACJE
# ======================
func update_animation():
	if action_state == ActionState.DASH:
		sprite.play("dash")
	elif action_state == ActionState.ATTACK:
		match attack_dir:
			AttackDirection.FORWARD: sprite.play("attack")
			AttackDirection.UP: sprite.play("attack_up")
			AttackDirection.DOWN: sprite.play("attack_down")
		$attack_hitbox/Sprite2D.show() #testowe
	else:
		match move_state:
			MovementState.IDLE: sprite.play("idle")
			MovementState.RUN: sprite.play("run")
			MovementState.JUMP: sprite.play("jump")
			MovementState.DOUBLE_JUMP: sprite.play("double_jump")
			MovementState.FALL: sprite.play("fall")
			MovementState.WALL_SLIDE: sprite.play("wall_slide")

	sprite.flip_h = facing_dir < 0


func _on_hitbox_area_entered(area: Area2D) -> void:
	health_bar.health-=10
