extends Node

var coins: int = 0
var score: int = 0
var lives: int = 3
var time: int = 900
var game_paused := false
var player_form: int = 0

signal item_box_changed(item: String)

var item_box: String = ""   # "", "mushroom", "fire_flower" ou "hammer"

const START_LIVES := 3
const START_TIME := 900
const DEATH_RESTART_DELAY := 3.0

func set_item_box(item: String) -> void:
	item_box = item
	item_box_changed.emit(item)

func add_coin(amount: int = 1) -> void:
	var old_coins := coins
	coins += amount

	# A cada 100 moedas, ganha uma vida
	if coins >= 100:
		var extra_lives := coins / 100
		lives += extra_lives
		coins %= 100

func restart_level() -> void:
	get_tree().paused = false
	game_paused = false
	time = START_TIME
	set_item_box("")
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

func new_game() -> void:
	lives = 3
	score = 0
	coins = 0
	time = 900
	game_paused = false
	set_item_box("")
	player_form = 0
