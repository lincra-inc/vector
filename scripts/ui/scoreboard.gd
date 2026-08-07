extends PanelContainer
class_name Scoreboard

@onready var players_list: VBoxContainer = $VBoxContainer/Players
@onready var player_template: TextureRect = $VBoxContainer/Players/TextureRect

func _ready():
	player_template.hide()
	hide()


func show_scoreboard():
	#player_template.hide() # @HACK: Idk why i cannot put it in the _ready
	show()
	refresh()


func hide_scoreboard():
	hide()


func refresh():
	for child in players_list.get_children():
		if child == player_template:
			continue
		child.queue_free()
	
	var main = get_tree().current_scene
	var players: Node3D = main.players
	
	for player in players.get_children():
		if player is not Player:
			continue
		
		var rect := player_template.duplicate()
		rect.show()
		
		var label := rect.get_node("Label") # o el nombre correcto
		label.text = "%s     %d / %d" % [
			player.network_state.player_name,
			player.network_state.kills,
			player.network_state.deaths]
		
		players_list.add_child(rect)
