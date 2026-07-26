extends Node
class_name PlayerState

@export var max_health := 100.0
@export var health := 100.0

@export var shield := 0.0

@rpc("any_peer", "call_remote", "reliable")
func set_health(value: float):
	health = value

@rpc("any_peer", "call_remote", "reliable")
func set_max_health(value: float):
	max_health = value
