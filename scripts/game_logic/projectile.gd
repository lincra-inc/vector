extends Area3D

@export var speed: float = 80.0
@export var lifetime: float = 3.0

var direction: Vector3

func setup(start_direction: Vector3) -> void:
	direction = start_direction.normalized()


func _physics_process(delta: float) -> void:
	if !multiplayer.is_server():
		return
	
	position += direction * speed * delta


func _ready() -> void:
	if multiplayer.is_server():
		await get_tree().create_timer(lifetime).timeout
		queue_free()
