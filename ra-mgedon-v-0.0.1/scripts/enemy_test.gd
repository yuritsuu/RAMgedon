extends CharacterBody2D

var hp=100
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(hp)
	if hp <=0:
		queue_free()


func take_damage(damage):
	hp-=damage
