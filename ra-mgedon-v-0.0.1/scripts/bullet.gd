extends CharacterBody2D

@export var speed: float = 2000
@export var damage: int = 15
@export var knockback_force: float = 150
@export var lifetime: float = 2.0

var life_timer: float = 0.0

func _ready():
	life_timer = lifetime

func _physics_process(delta: float) -> void:
	# przesunięcie pocisku
	var collision = move_and_collide(velocity * delta)
	if collision:
		# jeśli trafimy w cokolwiek z metodą take_damage
		var enemy = collision.get_collider()
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			if enemy.has_method("apply_knockback"):
				var force = velocity.normalized() * knockback_force
				enemy.apply_knockback(force)

		queue_free()  # zniszcz pocisk po kolizji
		return

	# licznik życia
	life_timer -= delta
	if life_timer <= 0:
		queue_free()

# Ustaw kierunek pocisku przy tworzeniu
func set_direction(dir: Vector2) -> void:
	velocity = dir.normalized() * speed
	rotation = dir.angle()
