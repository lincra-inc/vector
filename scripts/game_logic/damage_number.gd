extends Node3D
class_name DamageNumber

@export var lifetime: float = 1.0
@export var move_speed: float = 1.5

@onready var label: Label3D = $Label3D

var damage: int = 0
var timer := 0.0


func setup(value: int) -> void:
	damage = value


func _ready() -> void:
	label.text = str(damage)
	
	if(damage > 1):
		label.modulate = Color.RED
	
	if multiplayer.is_server():
		await get_tree().create_timer(lifetime).timeout
	
		if is_inside_tree():
			queue_free()


func _process(delta: float) -> void:
	position.y += move_speed * delta
	timer += delta
	
	var alpha := 1.0 - (timer / lifetime)
	label.modulate.a = alpha
	label.outline_modulate.a = alpha
	
	if timer >= lifetime:
		pass
		queue_free()
