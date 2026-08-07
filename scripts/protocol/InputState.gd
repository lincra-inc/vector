extends Node
class_name InputState

@export var shoot_sequence: int = 0
@export var shoot_position: Vector3
@export var shoot_direction: Vector3

@export var footstep_sequence : int = 0
@export var jump_sequence     : int = 0
@export var damage_sequence   : int = 0
@export var apply_damage      : float = 0

@export var respawn_request   : bool = false
