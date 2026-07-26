extends Node3D

var lifetime: float = 3.0

var timer := 0.0

func setup(damage: float) -> void:
	pass

func _process(delta: float) -> void:
	timer += delta
	
	if timer >= lifetime:
		queue_free()
