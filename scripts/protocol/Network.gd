extends Node

const DEDICATED_SERVER:    String = "--server"
const DEFAULT_PORT:        int = 7777
const DEFAULT_MAX_CLIENTS: int = 32

signal server_started(port: int)
signal server_stopped()

signal connected_to_server()
signal connection_failed()
signal server_disconnected()

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

var _peer: ENetMultiplayerPeer
var _spawner: MultiplayerSpawner

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

	return multiplayer.get_peers().size() + 1


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

func spawn_projectile(
	position: Vector3,
	direction: Vector3
) -> void:

	if !is_server():
		return

	if _spawner == null:
		push_error("MultiplayerSpawner no registrado.")
		return

	_spawner.spawn({
		"type": "projectile",
		"position": position,
		"direction": direction.normalized()
	})
	
var last_processed_shot: Dictionary = {}
func process_player_actions(players: Node) -> void:
	if !is_server():
		return
	
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
			input.shoot_direction
		)
