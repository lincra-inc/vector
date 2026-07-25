extends Node

@export var loot_spawn_interval := 5.0
@export var loot_min_distance := 1.0

var loot_spawn_timer := 0.0

const DEDICATED_SERVER:    String = "--server"
const DEFAULT_PORT:        int = 7777
const DEFAULT_MAX_CLIENTS: int = 32

const DEBUG_IN_LOCAL: bool = true

signal server_started(port: int)
signal server_stopped()

signal connected_to_server()
signal connection_failed()
signal server_disconnected()

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

var _peer: ENetMultiplayerPeer
var _spawner: MultiplayerSpawner
var _spawner_loots: MultiplayerSpawner

var last_processed_shot: Dictionary = {}

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

func spawn_loot_box(position: Vector3, modifier: int) -> void:
	if !is_server():
		return
	
	if _spawner_loots == null:
		push_error("MultiplayerSpawner no registrado.")
		return
	
	_spawner_loots.spawn({
		"type": "loot_modifier",
		"position": position,
		"modifier": modifier
	})

func spawn_projectile(position: Vector3, direction: Vector3, shooter: int, weapon: WeaponData) -> void:
	
	if !is_server():
		return
	
	if _spawner == null:
		push_error("MultiplayerSpawner no registrado.")
		return
	
	_spawner.spawn({
		"type": "projectile",
		"position": position,
		"direction": direction.normalized(),
		"id": shooter,
		"damage": weapon.damage,
		"speed": weapon.projectile_speed,
		"lifetime": weapon.projectile_lifetime
	})

func process_player_actions(players: Node, loots: Node) -> void:
	if !is_server():
		return
	
	for loot in loots.get_children():
		for player in players.get_children():
			if loot.global_position.distance_to(player.global_position) > 2.0:
				continue
			
			#player.weapon_data.apply_modifier(loot.modifier)
			loot.queue_free()
	
	for node: Node in players.get_children():
		var player := node as Player
		
		if player == null:
			continue
		
		if player.input_state == null:
			continue
			
		var input := player.input_state
		
		var last: int = last_processed_shot.get(player.name, 0)
		
		if input.shoot_sequence == last:
			continue
		
		last_processed_shot[player.name] = input.shoot_sequence
		
		spawn_projectile(
			input.shoot_position,
			input.shoot_direction,
			player.peer_id,
			player.weapon_data
		)

func process_loot_spawn(delta: float, loot_spawn_area: Area3D, loots: Node) -> void:
	if !is_server():
		return
	
	loot_spawn_timer -= delta
	
	if loot_spawn_timer > 0.0:
		return
	
	loot_spawn_timer = loot_spawn_interval
	
	var position := _find_loot_spawn_position(
		loot_spawn_area,
		loots
	)
	
	if position == Vector3.INF:
		return
	
	spawn_loot_box(
		position,
		randi() % 8 # modifier aleatorio
	)

func _find_loot_spawn_position(area_pool: Area3D, loots: Node) -> Vector3:
	var index := randi_range(0, area_pool.get_child_count() - 1)
	var shape : CollisionShape3D = area_pool.get_child(index) as CollisionShape3D
	
	if shape == null:
		return Vector3.INF
	
	var box := shape.shape as BoxShape3D
	
	if box == null:
		return Vector3.INF
	
	for i in 20:
		var local := Vector3(
			randf_range(-box.size.x * 0.5, box.size.x * 0.5),
			randf_range(-box.size.y * 0.5, box.size.y * 0.5),
			randf_range(-box.size.z * 0.5, box.size.z * 0.5)
		)
		var world_pos := shape.global_transform * local
		var valid := true
		
		for loot in loots.get_children():
			if loot.global_position.distance_to(world_pos) < loot_min_distance:
				valid = false
				break
		
		if valid:
			return world_pos
	
	return Vector3.INF
