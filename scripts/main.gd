extends Node3D

const DEDICATED_SERVER := "--server"
const PORT             := 7777
const MAX_CLIENTS      := 32

@export var player_scene: PackedScene

@onready var players = $World/Players
@onready var ip      = $CanvasLayer/IPLineEdit
@onready var Canvas  = $CanvasLayer

func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	
	var args = OS.get_cmdline_args()
	
	if DEDICATED_SERVER in OS.get_cmdline_args():
		$CanvasLayer.hide()
	
	if DEDICATED_SERVER in args:
		start_server()
	else:
		$CanvasLayer.hide()
		_on_join_button_pressed()

func disconnect_from_server():
	if multiplayer.multiplayer_peer == null:
		return
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		disconnect_from_server()
		get_tree().quit()

func _exit_tree():
	disconnect_from_server()

func start_server():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_CLIENTS)
	
	if err != OK:
		push_error("No pudo iniciar el servidor")
		get_tree().quit()
		return
		
	multiplayer.multiplayer_peer = peer
	
	print("--------------------------------")
	print("Servidor iniciado")
	print("Puerto: ", PORT)
	print("--------------------------------")
	
	#if not DEDICATED_SERVER in OS.get_cmdline_args():
	#	_spawn(multiplayer.get_unique_id())

func _on_host_button_pressed():
	start_server()
	Canvas.hide()

func _spawn(id):
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = Vector3(
		randf()*6.0,
		0,
		randf()*6.0
	)
	players.add_child(player, true)

func _on_join_button_pressed():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip.text, PORT)
	
	if err != OK:
		return
		
	multiplayer.multiplayer_peer = peer
	Canvas.hide()


func _peer_connected(id):
	if multiplayer.is_server():
		_spawn(id)


func _peer_disconnected(id):
	if players.has_node(str(id)):
		players.get_node(str(id)).queue_free()


@rpc("authority","reliable")
func spawn_existing_players(new_peer):
	if multiplayer.get_unique_id() != new_peer:
		return
	
	for child in players.get_children():
		if child.name == str(new_peer):
			continue
		
		var p = player_scene.instantiate()
		
		p.name = child.name
		p.player_id = int(child.name)
		p.position = child.position
		
		players.add_child(p,true)
