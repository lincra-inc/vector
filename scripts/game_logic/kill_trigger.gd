extends Node3D

@onready var players: Node3D = $"../../World/Players"

func _ready() -> void:
	players = $"../../World/Players"

func _on_area_entered(area: Area3D) -> void:
	if !Network.is_server():
		return
		
	var _player := area.get_parent() as Player
	
	if _player:
		for node: Node in players.get_children():
			var player := node as Player
			
			if player != null and _player.peer_id == player.peer_id:
				player.die(-1)
