extends Node
class_name CameraShake

@export var camera: Camera3D

var effect: float = 0.0

@export var effect_decay := 2.0

@export var max_translation := Vector3(
	0.08,
	0.08,
	0.0
)

@export var max_rotation := Vector3(
	3.0,
	3.0,
	1.0
)

var _base_position: Vector3
var _base_rotation: Vector3
var noise := FastNoiseLite.new()

func _ready() -> void:
	_base_position = camera.position
	_base_rotation = camera.rotation
	noise.seed = randi()
	noise.frequency = 25.0


func _process(delta: float) -> void:
	effect = max(effect - effect_decay * delta, 0.0)
	
	var amount := effect * effect
	var t := Time.get_ticks_msec() * 0.001
	
	camera.position = _base_position + Vector3(
		noise.get_noise_2d(t, 0),
		noise.get_noise_2d(t, 100),
		noise.get_noise_2d(t, 200)
	) * max_translation * amount
	
	camera.rotation = _base_rotation + Vector3(
		deg_to_rad(noise.get_noise_2d(t, 300) * max_rotation.x),
		deg_to_rad(noise.get_noise_2d(t, 400) * max_rotation.y),
		deg_to_rad(noise.get_noise_2d(t, 500) * max_rotation.z)
	) * amount

func add_shake(amount: float) -> void:
	effect = clamp(effect + amount, 0.0, 1.0)
