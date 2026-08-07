extends Node

const RANDOM_NAMES := [
	"Player",
	"Cronopio",
	"Fama",
	"Esperanza",
	"Reloj Verde",
	"Gliglico",
	"Mancuspia",
	"Toco",
	"Tantalia",
	"Pizarron",
	"Rana Azul",
	"Ciruela Lunar",
	"Perinola",
	"Triciclo",
	"Escarabajo",
	"Nimbo",
	"Luciernaga",
	"Maga Gris",
	"Paraguas",
	"Nube Baja",
	"Mandarina",
	"Rocamadour",
	"Oliva",
	"Pecera",
	"Caleidoscopio",
	"Horacio",
	"Silfo",
	"Cronopito",
	"Esperancin",
	"Famastico",
	"Axolotl"
]

var player_name : String = RANDOM_NAMES.pick_random()
var always_run:   bool   = false

@export var gamepad_look_sensitivity := 3.0
@export var mouse_look_sensitivity   := 0.003
