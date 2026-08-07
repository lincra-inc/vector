extends Node3D
class_name Projectile

var weapon: WeaponData

var speed: float = 80.0
var lifetime: float = 3.0
var damage: float = 1.0

var owner_peer_id: int
var direction: Vector3
var waiting_remove: bool = false

@export var audio_stream_list: Array[AudioStream]

func setup(start_direction: Vector3, shooter: int, damage: float, projectile_speed: float, projectile_lifetime: float) -> void:
	direction = start_direction.normalized()
	owner_peer_id = shooter
	
	self.damage   = damage
	self.speed    = projectile_speed
	self.lifetime = projectile_lifetime
	
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

	var remaining_distance : float = speed * delta
	var step_size : float = 0.5 # Distancia máxima recorrida por comprobación

	var space_state := get_world_3d().direct_space_state

	while remaining_distance > 0.0:
		var distance : float = min(step_size, remaining_distance)

		var from := global_position
		var to := from + direction * distance

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_bodies = true
		query.collide_with_areas = true
		query.collision_mask = 1

		var result := space_state.intersect_ray(query)

		if !result.is_empty():
			global_position = result.position
			_on_hit(result)
			return

		global_position = to
		remaining_distance -= distance

func _on_hit(hit: Dictionary) -> void:
	if waiting_remove: 
		return
	
	var collider: Object = hit["collider"]
	
	var player := collider.get_parent() as Player
	
	if player:
		if player.network_state.dead or player.network_state.health <= 0:
			return
		
		var multiplier := 1.0
		
		if collider.has_meta("damage_multiplier"):
			multiplier = collider.get_meta("damage_multiplier")
		
		if player.peer_id == owner_peer_id:
			return
		
		var final_damage := int(damage * multiplier)
		player.take_damage(owner_peer_id, final_damage, -direction)
		
		Network.spawn_damage_number(
			hit["position"],
			final_damage,
			player.peer_id
		)
	
	Network.spawn_hit_wall(
		hit["position"],
		damage
	)
	
	queue_free()
	#destroy_after_sound()

func destroy_after_sound() -> void:
	waiting_remove = true;
	$Node3D.visible = false
	
	var audio := $AudioStreamPlayer3D
	if audio.playing:
		await audio.finished
	
	queue_free()
