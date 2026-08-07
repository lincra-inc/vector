extends CPUParticles3D

func _ready():
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color.RED,
		Color.ORANGE,
		Color.YELLOW,
		Color.TRANSPARENT
	])

	color_ramp = gradient
