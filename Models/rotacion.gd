extends Node3D

@export var rotation_speed: float = 90.0
@export var rotation_axis: Vector3 = Vector3.UP
@export var initial_angle: float = 0.0

func _ready():
	rotation = rotation_axis.normalized() * deg_to_rad(initial_angle)

func _process(delta):
	rotate(rotation_axis.normalized(), deg_to_rad(rotation_speed) * delta)
