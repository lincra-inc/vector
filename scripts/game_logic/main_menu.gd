extends Control

@onready var player_name: LineEdit = $VBoxContainer/LineEdit
@onready var start_button: Button = $VBoxContainer/Button

func _ready():
	player_name.grab_focus()
	var args := OS.get_cmdline_args()
	
	for arg in args:
		if arg.begins_with("--playername="):
			var name := arg.trim_prefix("--playername=")
			
			Globals.player_name = name
			get_tree().change_scene_to_file("res://main_scene/world.tscn")
			break
	
	if Network.DEDICATED_SERVER in args:
		get_tree().change_scene_to_file("res://main_scene/world.tscn")

func start_game():
	var name := player_name.text.strip_edges()
	
	if name.is_empty():
		name = "Player"
	
	# Guardar nombre globalmente
	Globals.player_name = name
	
	get_tree().change_scene_to_file("res://main_scene/world.tscn")


func _on_button_pressed() -> void:
	start_game()


func _on_line_edit_text_submitted(new_text: String) -> void:
	start_game()
