extends Node

var coins: int = 0
var score: int = 0
var lives: int = 3
var time: int = 900
var game_paused := false

signal item_box_changed(item: String)

var item_box: String = ""   # "", "mushroom", "fire_flower" ou "hammer"

func set_item_box(item: String) -> void:
	item_box = item
	item_box_changed.emit(item)

const START_LIVES := 3
const START_TIME := 900
const DEATH_RESTART_DELAY := 3.0  # tempo da animação de morte antes de reiniciar

func restart_level() -> void:
	get_tree().paused = false
	game_paused = false
	time = START_TIME
	set_item_box("")  # o Mario volta Small, então a caixa esvazia
	get_tree().reload_current_scene()

func on_player_died() -> void:
	var game_over := lives <= 0
	lives = max(lives - 1, 0)

	await get_tree().create_timer(DEATH_RESTART_DELAY, true).timeout

	if game_over:
		lives = START_LIVES
		score = 0
		coins = 0

	restart_level()
