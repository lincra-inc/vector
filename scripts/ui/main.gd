extends Node3D

@export var player_scene: PackedScene
@export var projectile_scene: PackedScene
@export var damage_number_scene: PackedScene

@onready var players: Node3D = $World/Players
@onready var ip = $CanvasLayer/IPLineEdit
@onready var canvas: CanvasLayer = $CanvasLayer
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

var entity_scenes: Dictionary = {}

func _ready() -> void:
	spawner.spawn_function = _spawn_entity
	Network._spawner = spawner
	
	entity_scenes = {
		"player": player_scene,
		"projectile": projectile_scene,
		"damage_number": damage_number_scene,
	}
	
	Network.peer_connected.connect(_peer_connected)
	Network.peer_disconnected.connect(_peer_disconnected)
	
	if Network.is_dedicated_server():
		canvas.hide()
		Network.start_server()
		return
	
	canvas.hide()
	_on_join_button_pressed()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Network.disconnect_server()
		get_tree().quit()

func _exit_tree() -> void:
	Network.disconnect_server()

func _on_host_button_pressed() -> void:
	var err := Network.start_server()
	
	if err != OK:
		push_error("No pudo iniciarse el servidor.")
		return
	
	canvas.hide()


func _on_join_button_pressed() -> void:
	var host_ip = ip.text;
	
	if Network.DEBUG_IN_LOCAL:
		host_ip = "localhost"
	
	var err := Network.join_server(host_ip)
	
	if err != OK:
		push_error("No pudo conectarse al servidor.")
		return
	
	canvas.hide()

func _peer_connected(id: int) -> void:
	if Network.is_server():
		spawner.spawn({
			"type": "player",
			"id": id,
			"position": Vector3(
				randf() * 6.0,
				1.0,
				randf() * 6.0
			)
		})

func _peer_disconnected(id: int) -> void:
	var player := players.get_node_or_null(str(id))
	if player:
		player.queue_free()

func _physics_process(_delta):
	Network.process_player_actions(players)
	
func _spawn_entity(data: Dictionary) -> Node:
	var scene: PackedScene = entity_scenes.get(data["type"])
	
	if scene == null:
		push_error("Entidad desconocida: %s" % data["type"])
		return null
	
	var entity := scene.instantiate()
	
	match data["type"]:
		"player":
			entity.name = str(data["id"])
			entity.position = data["position"]
			entity.setup(data["id"])
		"projectile":
			entity.position = data["position"]
			entity.setup(data["direction"], data["id"])
		"damage_number":
			entity.position = data["position"]
			entity.setup(data["damage"])
	return entity
