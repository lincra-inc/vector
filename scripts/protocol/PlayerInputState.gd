extends Node
class_name PlayerInputState

@export var kills := 0
@export var deaths := 0

@export var player_name: String
@export var shoot_sequence: int = 0
@export var shoot_position: Vector3
@export var shoot_direction: Vector3

@export var footstep_sequence: int = 0
@export var jump_sequence: int = 0
