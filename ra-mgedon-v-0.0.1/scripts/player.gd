extends CharacterBody2D

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	DOUBLE_JUMP,
	FALL,
	WALL_SLIDE,
	WALL_JUMP,
	DASH
}

var state = PlayerState.IDLE

# === RUCH ===
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# DOUBLE JUMP
var can_double_jump = true
const DOUBLE_JUMP_VELOCITY = -380.0

# === GRAWITACJA ===
const BASE_GRAVITY = 1200.0
const FALL_GRAVITY_MULT = 2.5
const MAX_FALL_SPEED = 1200.0
const JUMP_CUT_MULT = 0.4 # skrócenie skoku po puszczeniu przycisku

# === COYOTE TIME ===
const COYOTE_TIME = 0.12
var coyote_timer = 0.0

# === JUMP BUFFER ===
const JUMP_BUFFER_TIME = 0.12
var jump_buffer_timer = 0.0

# === DASH ===
const DASH_SPEED = 900.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 1.0

var can_dash = true
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO

# === WALL SLIDE / JUMP ===
const WALL_SLIDE_SPEED = 120.0
const WALL_JUMP_FORCE = Vector2(200, -550)
const WALL_JUMP_LOCK_TIME = 0.15
const WALL_JUMP_STATE_TIME = 0.4 # czas trwania stanu WALL_JUMP

var is_wall_sliding = false
var wall_jump_lock_timer = 0.0
var wall_jump_state_timer = 0.0 # nowa zmienna do utrzymania stanu WALL_JUMP

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta):
	print(state)
	handle_dash(delta)
	update_animation()

	if not is_dashing:
		apply_gravity(delta)
		handle_timers(delta)
		handle_wall_slide()
		handle_wall_jump(delta)
		handle_jump()
		handle_movement()
	
	if is_on_floor():
		can_dash = true
		can_double_jump = true
	move_and_slide()


# ======================
# GRAWITACJA
# ======================
func apply_gravity(delta):
	if not is_on_floor():
		if velocity.y < 0:
			# wznoszenie
			velocity.y += BASE_GRAVITY * delta
		else:
			# spadanie (mocniejsza grawitacja)
			velocity.y += BASE_GRAVITY * FALL_GRAVITY_MULT * delta
			velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		coyote_timer = COYOTE_TIME

	# Utrzymywanie WALL_JUMP stanu jeśli timer > 0
	if wall_jump_state_timer > 0:
		wall_jump_state_timer -= delta
		state = PlayerState.WALL_JUMP
	else:
		# normalne przypisywanie stanów
		if not is_on_floor():
			if velocity.y < 0 and can_double_jump:
				state = PlayerState.JUMP
			elif velocity.y < 0 and can_double_jump==false:
				state=PlayerState.DOUBLE_JUMP
			else:
				state = PlayerState.FALL
		else:
			if abs(velocity.x) > 0:
				state = PlayerState.RUN
			else:
				state = PlayerState.IDLE


# ======================
# TIMERY
# ======================
func handle_timers(delta):
	coyote_timer -= delta
	jump_buffer_timer -= delta


	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME


# ======================
# SKOK
# ======================
func handle_jump():
	# normalny skok + coyote time + buffer
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
		

	# skrócenie skoku po puszczeniu przycisku
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULT
	# DOUBLE JUMP
	if jump_buffer_timer > 0 and not is_on_floor() and can_double_jump and velocity.y > 0:
		velocity.y = DOUBLE_JUMP_VELOCITY
		jump_buffer_timer = 0
		can_double_jump = false
		state = PlayerState.DOUBLE_JUMP
	if jump_buffer_timer > 0 and can_double_jump==false and not is_on_floor() and velocity.y<0:
		state = PlayerState.DOUBLE_JUMP

# ======================
# RUCH POZIOMY
# ======================
func handle_movement():
	if wall_jump_lock_timer > 0:
		return

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor():
			state = PlayerState.RUN
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			state = PlayerState.IDLE


func handle_dash(delta):
	if is_dashing:
		state = PlayerState.DASH

	dash_cooldown_timer -= delta

	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		is_dashing = true
		can_dash = false
		dash_timer = DASH_TIME
		dash_cooldown_timer = DASH_COOLDOWN
		
		var input_dir = Vector2(
			Input.get_axis("left", "right"),
			Input.get_axis("up", "down")
		)
		dash_direction = input_dir.normalized()
		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2(sign(velocity.x), 0)
			if dash_direction == Vector2.ZERO:
				dash_direction = Vector2.RIGHT
	# LOGIKA DASHA
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED

		if dash_timer <= 0:
			is_dashing = false
			velocity.y = clamp(velocity.y, -200, MAX_FALL_SPEED)


func handle_wall_slide():
	if is_wall_sliding:
		state = PlayerState.WALL_SLIDE

	is_wall_sliding = false

	if not is_on_floor() and is_on_wall() and velocity.y > 0:
		is_wall_sliding = true
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)


func handle_wall_jump(delta):
	if wall_jump_lock_timer > 0:
		wall_jump_lock_timer -= delta

	if is_wall_sliding and Input.is_action_just_pressed("jump"):
		var wall_normal = get_wall_normal()
		velocity.x = wall_normal.x * WALL_JUMP_FORCE.x
		velocity.y = WALL_JUMP_FORCE.y
		wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
		wall_jump_state_timer = WALL_JUMP_STATE_TIME # ustaw timer WALL_JUMP
		state = PlayerState.WALL_JUMP


func update_animation():
	match state:
		PlayerState.IDLE:
			animated_sprite_2d.play("idle")
		PlayerState.RUN:
			animated_sprite_2d.play("run")
		PlayerState.JUMP:
			animated_sprite_2d.play("jump")
		PlayerState.FALL:
			animated_sprite_2d.play("fall")
		PlayerState.WALL_SLIDE:
			animated_sprite_2d.play("wall_slide")
		PlayerState.WALL_JUMP:
			animated_sprite_2d.play("wall_jump")
		PlayerState.DASH:
			animated_sprite_2d.play("dash")
		PlayerState.DOUBLE_JUMP:
			animated_sprite_2d.play("double_jump")
