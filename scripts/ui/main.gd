extends Node3D
class_name MainCore

@export var player_scene: PackedScene
@export var projectile_scene: PackedScene
@export var damage_number_scene: PackedScene
@export var loot_modifier_scene: PackedScene
@export var hit_wall_scene: PackedScene
@export var play_at_scene: PackedScene

@onready var players     : Node3D = $SubViewportContainer/SubViewport/World/Players
@onready var spawns_pool : Node3D = $SubViewportContainer/SubViewport/World/SpawnPools
@onready var loots       : Node3D = $SubViewportContainer/SubViewport/World/Loots
@onready var loots_pool  : Node3D = $SubViewportContainer/SubViewport/World/LootsPools
@onready var special_loots_pool : Node3D = $SubViewportContainer/SubViewport/World/SpecialPools
@onready var scoreboard  : PanelContainer = $CanvasLayer/Scoreboard
@onready var pause_menu  : PauseMenu = $CanvasLayer/Pause

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var spawner_loots: MultiplayerSpawner = $MultiplayerSpawnerLoots

var entity_scenes: Dictionary = {}

@onready var fps_label : Label = $CanvasLayer/FPS

func _ready() -> void:
	fps_label.hide()
	#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	players = $SubViewportContainer/SubViewport/World/Players
	
	if not Globals.always_run: #@NOTE(Liman1): Witch means is mobile.
		for child in $CanvasLayer.get_children():
			child.hide()
	
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

func _process(_delta):
	fps_label.text = (
	"FPS: %d\n" % Engine.get_frames_per_second() +
	"Draw Calls: %d\n" % RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME) +
	"Objects: %d\n" % RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME) +
	"Primitives: %d" % RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
)

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
			special_loots_pool,
			loots
		)
	
	Network.process_player_actions(players, loots, _delta)

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
			
			var player_color = data["color"]
			
			if DisplayServer.get_name() != "headless":
				var mesh_pov := entity.find_child("QuakeGuy_002", true, false) as MeshInstance3D
				var mesh_model := entity.find_child("QuakeGuy_001", true, false) as MeshInstance3D
				
				var material := mesh_pov.get_active_material(0) as ShaderMaterial
				var unique_material := material.duplicate() as ShaderMaterial
				mesh_pov.set_surface_override_material(0, unique_material)
				if unique_material:
					unique_material.set_shader_parameter("ColorParameter", player_color)
					
				var pov_material := mesh_model.get_active_material(0) as ShaderMaterial
				var unique_pov_material := pov_material.duplicate() as ShaderMaterial
				mesh_model.set_surface_override_material(0, unique_pov_material)
				if unique_pov_material:
					unique_pov_material.set_shader_parameter("ColorParameter", player_color)
			
			entity.setup(data["color"], data["id"])
		"projectile":
			entity.position = data["position"]
			entity.setup(data["direction"], data["color"], data["id"]
			, data["damage"], data["speed"], data["lifetime"], data["size"])
		"damage_number":
			entity.position = data["position"]
			entity.setup(data["damage"])
		"hit_wall":
			entity.position = data["position"]
			entity.setup(data["color"], data["damage"])
		"play_at":
			entity.position = data["position"]
			entity.setup(data["path"])
		"loot_modifier":
			entity.position = data["position"]
			entity.setup(data["is_static"], data["modifier_type"])
	return entity
