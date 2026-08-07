extends Node3D

func _on_area_entered(area: Area3D) -> void:
	if !Network.is_server():
		return
		
	var _player := area.get_parent() as Player
	
	if _player:
		var main = get_tree().current_scene
		var players : Node3D = main.players
		
		for node: Node in players.get_children():
			var player := node as Player
			
			if player != null and _player.peer_id == player.peer_id:
				player.take_damage(-1, 9999, Vector3.ZERO)
