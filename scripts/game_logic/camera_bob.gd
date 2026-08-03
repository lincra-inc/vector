extends Node
class_name CameraBob

@export var walk_frequency: float = 1.5
@export var run_frequency: float = 2.25

@export var walk_amplitude: float = 0.015
@export var run_amplitude: float = 0.02

@export var smoothing: float = 12.0

var time := 0.0

var position_offset := Vector3.ZERO

func update_bob(
	delta: float,
	speed_ratio: float,
	is_running: bool,
	is_grounded: bool
) -> void:

	if !is_grounded or speed_ratio < 0.05:
		position_offset = position_offset.lerp(Vector3.ZERO, smoothing * delta)
		return

	time += delta * lerpf(
		walk_frequency,
		run_frequency,
		clamp(speed_ratio, 0.0, 1.0)
	)

	var amp := lerpf(
		walk_amplitude,
		run_amplitude,
		clamp(speed_ratio, 0.0, 1.0)
	)

	var target := Vector3()

	target.x = sin(time * TAU) * amp * 0.45
	target.y = abs(cos(time * TAU)) * amp

	position_offset = position_offset.lerp(target, smoothing * delta)
