extends Node3D

@export var player_scene: PackedScene
@export var projectile_scene: PackedScene
@export var damage_number_scene: PackedScene
@export var loot_modifier_scene: PackedScene
@export var hit_wall_scene: PackedScene
@export var play_at_scene: PackedScene

@onready var players: Node3D = $World/Players
@onready var spawns_pool: Node3D = $World/SpawnPools
@onready var loots: Node3D = $World/Loots
@onready var loots_pool: Node3D = $World/LootsPools
@onready var scoreboard: PanelContainer = $CanvasLayer/Scoreboard

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var spawner_loots: MultiplayerSpawner = $MultiplayerSpawnerLoots


var entity_scenes: Dictionary = {}

func _ready() -> void:
	spawner.spawn_function = _spawn_entity
	spawner_loots.spawn_function = _spawn_entity
	Network._spawner = spawner
	Network._spawner_loots = spawner_loots
	
	entity_scenes = {
		"player": player_scene,
		"projectile": projectile_scene,
		"damage_number": damage_number_scene,
		"loot_modifier": loot_modifier_scene,
		"hit_wall": hit_wall_scene,
		"play_at": play_at_scene,
	}
	
	Network.peer_connected.connect(_peer_connected)
	Network.peer_disconnected.connect(_peer_disconnected)
	
	if Network.is_dedicated_server():
		scoreboard.visible = false
		Network.start_server()
		return
	
	scoreboard.visible = false
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
	


func _on_join_button_pressed() -> void:
	var host_ip = "130.94.106.209";
	
	if Network.DEBUG_IN_LOCAL:
		host_ip = "localhost"
	
	var err := Network.join_server(host_ip)
	
	if err != OK:
		push_error("No pudo conectarse al servidor.")
		return
	

func _peer_connected(id: int) -> void:
	if Network.is_server():
		Network.process_player_spawn(
			spawns_pool,
			players,
			id
		)
	

func _peer_disconnected(id: int) -> void:
	var player := players.get_node_or_null(str(id))
	if player:
		player.queue_free()

func _physics_process(_delta):
	if Network.is_server():
		Network.process_loot_spawn(
			_delta,
			loots_pool,
			loots
		)
	
	Network.process_player_actions(players, loots)

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
			entity.setup(data["direction"], data["id"]
			, data["damage"], data["speed"], data["lifetime"])
		"damage_number":
			entity.position = data["position"]
			entity.setup(data["damage"])
		"hit_wall":
			entity.position = data["position"]
			entity.setup(data["damage"])
		"play_at":
			entity.position = data["position"]
			entity.setup(data["path"])
		"loot_modifier":
			entity.position = data["position"]
			entity.setup(data["modifier_type"])
	return entity
