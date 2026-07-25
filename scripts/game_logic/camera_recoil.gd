extends Node
class_name CameraRecoil

@export var return_speed: float = 1.4
@export var snappiness: float = 12.0

@export var max_vertical_recoil: float   = 150.0
@export var max_horizontal_recoil: float = 7.5

var rotation_offset: Vector2 = Vector2.ZERO
var target_offset: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	target_offset = target_offset.move_toward(
		Vector2.ZERO,
		return_speed * delta
	)
	
	rotation_offset = rotation_offset.lerp(
		target_offset,
		snappiness * delta
	)


func add_recoil(pitch: float, yaw: float = 0.0) -> void:
	target_offset.x += pitch
	
	target_offset.y += randf_range(
		-yaw,
		yaw
	)
	
	target_offset.x = clamp(
		target_offset.x,
		0.0,
		deg_to_rad(max_vertical_recoil)
	)

	target_offset.y = clamp(
		target_offset.y,
		-deg_to_rad(max_horizontal_recoil),
		deg_to_rad(max_horizontal_recoil)
	)
