extends Node3D
class_name Projectile

@export var speed: float = 40.0
@export var lifetime: float = 3.0

var owner_peer_id: int
var direction: Vector3
var waiting_remove: bool = false

@export var audio_stream_list: Array[AudioStream]

func setup(start_direction: Vector3, shooter: int) -> void:
	direction = start_direction.normalized()
	owner_peer_id = shooter
	
	if audio_stream_list.size() > 0:
		var index := randi_range(0, audio_stream_list.size() - 1)
		
		$AudioStreamPlayer3D.stream = audio_stream_list[index]

func _ready() -> void:
	look_at(global_position + direction, Vector3.UP)
	if multiplayer.is_server():
		await get_tree().create_timer(lifetime).timeout
		queue_free()

	if multiplayer.is_server():
		await get_tree().create_timer(lifetime).timeout

		if is_inside_tree():
			queue_free()

func _physics_process(delta: float) -> void:
	if waiting_remove: 
		return
	
	if !multiplayer.is_server():
		return
	
	var from := global_position
	var to := from + direction * speed * delta
	
	var space_state := get_world_3d().direct_space_state
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 1
	var result := space_state.intersect_ray(query)
	
	if !result.is_empty():
		_on_hit(result)
		return
	
	global_position = to

func _on_hit(hit: Dictionary) -> void:
	if waiting_remove: 
		return
	
	var collider: Object = hit["collider"]
	
	var player := collider.get_parent() as Player
	
	if player:
		
		var multiplier := 1.0
		
		if collider.has_meta("damage_multiplier"):
			multiplier = collider.get_meta("damage_multiplier")
		
		var damage := int(20 * multiplier)
		Network.spawn_damage_number(
			hit["position"],
			damage,
			player.peer_id
		)
	
	destroy_after_sound()

func destroy_after_sound() -> void:
	waiting_remove = true;
	var audio := $AudioStreamPlayer3D
	
	if audio.playing:
		await audio.finished
	
	queue_free()
