extends PanelContainer
class_name PauseMenu

@onready var sound_slider: HSlider = $VBoxContainer/TextureRect2/VBoxContainer2/VBoxContainer/sound
@onready var music_slider: HSlider = $VBoxContainer/TextureRect2/VBoxContainer2/VBoxContainer/music
@onready var sensitivity_slider: HSlider = $VBoxContainer/TextureRect2/VBoxContainer2/VBoxContainer/sensitivity

@onready var resume_button: Button = $VBoxContainer/TextureRect2/VBoxContainer2/VBoxContainer/HBoxContainer/resume
@onready var main_menu_button: Button = $VBoxContainer/TextureRect2/VBoxContainer2/VBoxContainer/HBoxContainer/options

var paused : bool = false
var main_core : MainCore

func _ready():
	if Network.is_dedicated_server():
		return
	
	var main_node = get_tree().current_scene
	main_core = main_node as MainCore
	visible = false

	sound_slider.min_value = 0
	sound_slider.max_value = 100
	sound_slider.step = 1

	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1

	sensitivity_slider.min_value = 0.1
	sensitivity_slider.max_value = 10.0
	sensitivity_slider.step = 0.1

	sound_slider.value = 100
	music_slider.value = 100
	sensitivity_slider.value = 3.0

	sound_slider.value_changed.connect(_on_sound_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

	resume_button.pressed.connect(resume_game)
	if main_menu_button:
		main_menu_button.pressed.connect(go_to_main_menu)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			resume_game()
		else:
			pause_game()

func pause_game():
	paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume_game():
	paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func go_to_main_menu():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_sound_changed(value: float):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value / 100.0)
	)

func _on_music_changed(value: float):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(value / 100.0)
	)

func _on_sensitivity_changed(value: float):
	Globals.mouse_look_sensitivity   = value / 1000
	Globals.gamepad_look_sensitivity = value
