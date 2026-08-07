extends Node

@export var loot_spawn_interval := 5.0
@export var loot_min_distance := 5.0

var loot_spawn_timer := 0.0

const DEDICATED_SERVER:    String = "--server"
const DEFAULT_PORT:        int = 7770
const DEFAULT_MAX_CLIENTS: int = 32

const DEBUG_IN_LOCAL: bool = false

signal server_started(port: int)
signal server_stopped()

signal connected_to_server()
signal connection_failed()
signal server_disconnected()

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

var _peer : ENetMultiplayerPeer
var _spawner : MultiplayerSpawner
var _spawner_loots : MultiplayerSpawner

var last_processed_shot: Dictionary = {}
var last_footstep_sequence: Dictionary = {}
var last_jump_sequence: Dictionary = {}
var last_damage_sequence: Dictionary = {}

var regen_timer := 0.0

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	multiplayer.connected_to_server.connect(
		func():
			connected_to_server.emit()
	)

	multiplayer.connection_failed.connect(
		func():
			connection_failed.emit()
	)

	multiplayer.server_disconnected.connect(
		func():
			server_disconnected.emit()
	)

func start_server(port: int = DEFAULT_PORT, ax_clients: int = DEFAULT_MAX_CLIENTS) -> Error:
	if multiplayer.multiplayer_peer != null:
		disconnect_server()
	
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(DEFAULT_PORT, DEFAULT_MAX_CLIENTS)
	
	if err != OK:
		push_error("No pudo iniciarse el servidor.")
		_peer = null
		return err
	
	multiplayer.multiplayer_peer = _peer
	
	print("--------------------------------")
	print("Servidor iniciado")
	print("Puerto: ", port)
	print("--------------------------------")
	
	server_started.emit(port)
	return OK

func join_server(ip: String, port: int = DEFAULT_PORT) -> Error:
	if multiplayer.multiplayer_peer != null:
		disconnect_server()
	
	_peer = ENetMultiplayerPeer.new()
	
	var err := _peer.create_client(ip, port)
	
	if err != OK:
		_peer = null
		return err
	
	multiplayer.multiplayer_peer = _peer
	
	return OK

func disconnect_server() -> void:
	if multiplayer.multiplayer_peer == null:
		return
	
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	_peer = null
	
	server_stopped.emit()

func is_server() -> bool:
	return multiplayer.is_server()

func get_peer_id() -> int:
	return multiplayer.get_unique_id()


func get_player_count() -> int:
	if multiplayer.multiplayer_peer == null:
		return 0
	return multiplayer.get_peers().size()


func get_ip() -> String:
	if multiplayer.multiplayer_peer == null:
		return ""
	if _peer == null:
		return ""
	return _peer.get_host().get_local_address()


func is_dedicated_server() -> bool:
	return DEDICATED_SERVER in OS.get_cmdline_args()

func _on_peer_connected(id: int) -> void:
	print("Jugador conectado: ", id)
	print("Jugadores: ", get_player_count())
	
	peer_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("Jugador desconectado: ", id)
	print("Jugadores: ", get_player_count())
	
	peer_disconnected.emit(id)

func spawn_damage_number(position: Vector3, damage: int, id: int) -> void:
	if !is_server():
		return
	
	_spawner.spawn({
		"type": "damage_number",
		"position": position,
		"damage": damage,
		"id": id
	})

func spawn_hit_wall(position: Vector3, color: Color, damage: int) -> void:
	if !is_server():
		return
	
	_spawner.spawn({
		"type": "hit_wall",
		"position": position,
		"color": color,
		"damage": damage
	})

func spawn_play_at(position: Vector3, path: String) -> void:
	if !is_server():
		return
	
	_spawner.spawn({
		"type": "play_at",
		"position": position,
		"path": path
	})

func spawn_loot_box(position: Vector3, is_static: bool, modifier_type: int) -> void:
	if !is_server():
		return
	
	if _spawner_loots == null:
		push_error("MultiplayerSpawner no registrado.")
		return
	
	_spawner_loots.spawn({
		"type": "loot_modifier",
		"position": position,
		"is_static": is_static,
		"modifier_type": modifier_type
	})

func spawn_projectile(position: Vector3, direction: Vector3, color: Color, shooter: int, weapon: WeaponData) -> void:
	if !is_server():
		return
	
	if _spawner == null:
		push_error("MultiplayerSpawner no registrado.")
		return
		
	var final_damage = weapon.damage + randf_range(-3.0, 3.0)
	
	_spawner.spawn({
		"type": "projectile",
		"position": position,
		"direction": direction.normalized(),
		"color": color,
		"id": shooter,
		"damage": final_damage,
		"speed": weapon.projectile_speed,
		"lifetime": weapon.projectile_lifetime,
		"size": weapon.projectile_size
	})

func process_player_actions(players: Node, loots: Node, delta: float) -> void:
	if !is_server():
		return
	
	for loot in loots.get_children():
		for player in players.get_children():
			var _player := player as Player
			
			if _player == null or _player.network_state.dead or _player.network_state.health <= 0:
				continue
			
			if loot.global_position.distance_to(player.global_position) > 2.0:
				continue
			
			Network.spawn_hit_wall(
				loot.position,
				loot.color,
				0
			)
			
			spawn_play_at(loot.position, "res://sounds/1up.mp3")
			loot.queue_free()
			
			var modifier := loot as LootModifier
			
			if modifier != null:
				_player.weapon_data.apply_modifier(modifier)
				if modifier.jump_boost <= 0:
					_player.network_state.score += 1
	
	for node: Node in players.get_children():
		var player := node as Player
		
		if player == null:
			continue
		
		if player.input_state == null:
			continue
		
		update_regeneration(player, delta)
		
		var input := player.input_state
		
		var dmg := player.input_state.damage_sequence
		var last_dmg : int = last_damage_sequence.get(player.peer_id, 0)
		if dmg != last_dmg:
			last_damage_sequence[player.peer_id] = dmg
			player.take_damage(-1, player.input_state.apply_damage, Vector3(randf(), randf(), randf()))
		
		var jump := player.input_state.jump_sequence
		var last_jump : int = last_jump_sequence.get(player.peer_id, 0)
		if jump != last_jump:
			last_jump_sequence[player.peer_id] = jump
			Network.spawn_play_at(player.global_position,"res://sounds/jumppp11.ogg")
		
		var step := player.input_state.footstep_sequence
		var last_foot : int = last_footstep_sequence.get(player.peer_id, 0)
		if step != last_foot:
			last_footstep_sequence[player.peer_id] = step
			Network.spawn_play_at(player.global_position,"res://sounds/stone01.ogg")
		
		var last: int = last_processed_shot.get(player.name, 0)
		
		if input.shoot_sequence == last:
			continue
		
		last_processed_shot[player.name] = input.shoot_sequence
		
		for i in range(player.weapon_data.projectile_per_shoot):
			var direction := input.shoot_direction
			if i > 0:
				direction = direction.rotated(
					Vector3.UP,
					deg_to_rad(randf_range(-2.0, 2.0))
				)
				direction = direction.rotated(
					player.head.global_transform.basis.x,
					deg_to_rad(randf_range(-2.0, 2.0))
				)
				direction = direction.normalized()
			
			spawn_projectile(
				input.shoot_position,
				direction,
				player.player_color,
				player.peer_id,
				player.weapon_data
			)


func process_player_spawn(player_spawn_area: Area3D, players: Node, id: int) -> void:
	if !is_server():
		return
	
	var position := _find_spawn_position(
		player_spawn_area,
		players,
		10.0
	)
	
	if position == Vector3.INF:
		position = Vector3.ZERO
	
	var player_color : Color = Color(randf(), randf(), randf(), 1.0)
	_spawner.spawn({
		"type": "player",
		"id": id,
		"color": player_color,
		"position": position
	})

func process_loot_spawn(delta: float, loot_spawn_area: Area3D, special_loot_spawn_area: Area3D, loots: Node) -> void:
	if !is_server():
		return
	
	loot_spawn_timer -= delta
	if loot_spawn_timer > 0.0:
		return
	
	var loot_index : int = randi() % 20
	var pool = loot_spawn_area
	if loot_index > 17: # TEMP!
		pool = special_loot_spawn_area
	
	var position := _find_spawn_position(
		pool,
		loots,
		loot_min_distance,
	)
	
	if position == Vector3.INF:
		return
	
	loot_spawn_timer = loot_spawn_interval
	
	spawn_loot_box(
		position,
		true,
		loot_index
	)

func _find_spawn_position(area_pool: Area3D, parent_pool: Node, min_distance: float) -> Vector3:
	var index := randi_range(0, area_pool.get_child_count() - 1)
	var shape := area_pool.get_child(index) as CollisionShape3D
	
	if shape == null:
		return Vector3.INF

	var box := shape.shape as BoxShape3D

	if box == null:
		return Vector3.INF

	var valid_positions: Array[Vector3] = []

	for i in 40:
		var local := Vector3(
			randf_range(-box.size.x * 0.5, box.size.x * 0.5),
			randf_range(-box.size.y * 0.5, box.size.y * 0.5),
			randf_range(-box.size.z * 0.5, box.size.z * 0.5)
		)

		var world_pos := shape.global_transform * local
		var valid := true

		for pool in parent_pool.get_children():
			if pool.global_position.distance_to(world_pos) < min_distance:
				valid = false
				break

		if valid:
			valid_positions.append(world_pos)

	if valid_positions.is_empty():
		return Vector3.INF

	return valid_positions.pick_random()

func get_random_player_spawn(player_spawn_area: Area3D, players: Node) -> Vector3:
	if !is_server():
		return Vector3.INF

	return _find_spawn_position(
		player_spawn_area,
		players,
		5.0
	)

func update_regeneration(player: Player, delta: float):
	if player.network_state.regeneration > 0.0:
		regen_timer += delta
		
		if regen_timer >= 1.0:
			regen_timer -= 1.0
			
			player.network_state.regeneration -= 5.0
			if player.network_state.regeneration < 0.0:
				player.network_state.regeneration = 0.0
			
			player.network_state.health += 5.0
	else:
		regen_timer = 0.0
