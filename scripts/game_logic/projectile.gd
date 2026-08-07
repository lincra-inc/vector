extends Node3D
class_name Projectile

var weapon: WeaponData

var speed: float = 80.0
var lifetime: float = 3.0
var damage: float = 1.0
var size: float = 1.0

var owner_peer_id: int
var owner_color: Color
var direction: Vector3
var waiting_remove: bool = false

var lifetime_timer := 0.0
var destroy_when_sound_ends := false

@export var audio_stream_list: Array[AudioStream]

func setup(start_direction: Vector3, color: Color, shooter: int, damage: float, projectile_speed: float, projectile_lifetime: float, projectile_size: float) -> void:
	size = projectile_size
	
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color])
	$Node3D/CPUParticles3D.color = color
	$Node3D/CPUParticles3D.color_ramp = gradient
	owner_color = color
	
	direction = start_direction.normalized()
	owner_peer_id = shooter
	
	self.damage   = damage
	self.speed    = projectile_speed
	self.lifetime = projectile_lifetime
	
	if audio_stream_list.size() > 0:
		var index := randi_range(0, audio_stream_list.size() - 1)
		
		$AudioStreamPlayer3D.stream = audio_stream_list[index]

func _ready():
	$Node3D/CPUParticles3D.scale_amount_max = size
	look_at(global_position + direction, Vector3.UP)
	lifetime_timer = lifetime

func _physics_process(delta):
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		queue_free()
	
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
	
	var loot := collider.get_parent() as LootModifier
	
	if loot:
		if loot.landed or loot.is_static:
			Network.spawn_hit_wall(
				hit["position"],
				loot.color,
				damage
			)
			loot.queue_free()
	elif player:
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
			owner_color,
			damage
		)
		queue_free()
	else:
		Network.spawn_hit_wall(
			hit["position"],
			owner_color,
			damage
		)
		if is_instance_valid(self):
			queue_free()
	
	
	#destroy_after_sound()

func destroy_after_sound():
	waiting_remove = true
	$Node3D.visible = false

	if $AudioStreamPlayer3D.playing:
		destroy_when_sound_ends = true
	else:
		queue_free()
