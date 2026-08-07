extends Node3D

var lifetime: float = 3.0

var timer := 0.0

func setup(color: Color, damage: float) -> void:
	if color != Color.BLACK:
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([
			color,
			Color.TRANSPARENT
		])

		$ParticleExplosion.color_ramp = gradient

func _process(delta: float) -> void:
	timer += delta
	
	if timer >= lifetime:
		queue_free()
