extends PanelContainer
class_name Scoreboard

@onready var players_list: VBoxContainer = $VBoxContainer/Players

func _ready():
	hide()


func show_scoreboard():
	show()
	refresh()


func hide_scoreboard():
	hide()


func refresh():
	for child in players_list.get_children():
		child.queue_free()
	
	var main = get_tree().current_scene
	var players : Node3D = main.players
	
	for player in players.get_children():
		if player is not Player:
			continue
		
		var label := Label.new()
		
		label.text = "%s     %d / %d" % [
			player.network_state.player_name,
			player.network_state.kills,
			player.network_state.deaths
		]
		
		players_list.add_child(label)
