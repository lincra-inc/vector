extends Node
class_name PlayerInputState


@export var movement: Vector2 = Vector2.ZERO
@export var look: Vector2 = Vector2.ZERO
@export var jump: bool = false

@export var shoot_sequence: int = 0
@export var shoot_position: Vector3
@export var shoot_direction: Vector3
