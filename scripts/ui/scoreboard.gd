extends PanelContainer

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

	var players := get_tree().current_scene.get_node(
		"World/Players"
	)

	for player in players.get_children():
		if player is not Player:
			continue

		var label := Label.new()

		label.text = "%s     %d / %d" % [
			player.input_state.player_name,
			player.input_state.kills,
			player.input_state.deaths
		]

		players_list.add_child(label)
