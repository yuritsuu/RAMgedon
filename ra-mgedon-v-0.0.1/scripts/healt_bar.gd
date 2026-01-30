extends ProgressBar

# ======================
# REFERENCJE
# ======================
@onready var damage_bar: ProgressBar = $DamageBar
@onready var timer: Timer = $Timer

# ======================
# HEALTH
# ======================
var health: int = 0: set=_set_health    # bieżące HP (getter/setter)
# max_value ProgressBar pochodzi z PlayerStats.MAX_HP

# ======================
# READY
# ======================
func _ready() -> void:
	# Ustawiamy max_value PRZED przypisaniem health
	max_value = PlayerStats.MAX_HP
	health = PlayerStats.HP
	value = health
	damage_bar.max_value = max_value
	damage_bar.value = health

# ======================
# SETTER HEALTH
# ======================
func _set_health(new_health: int) -> void:
	var prev_health = health
	health = clamp(new_health, 0, PlayerStats.MAX_HP)   # clamp do max HP
	value = health
	PlayerStats.HP = health

	# jeśli gracz zginie, reload sceny
	if health <= 0:
		PlayerStats.HP = PlayerStats.MAX_HP   # reset HP po reloadzie
		get_tree().reload_current_scene()
		return

	# animacja damage bara
	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health

# ======================
# INICJALIZACJA HP (np. na start gry lub po buffie)
# ======================
func init_health(_health: int) -> void:
	max_value = PlayerStats.MAX_HP
	health = clamp(_health, 0, max_value)
	value = health
	damage_bar.max_value = max_value
	damage_bar.value = health


# ======================
# TIMER DAMAGE BAR
# ======================
func _on_timer_timeout() -> void:
	damage_bar.value = health
