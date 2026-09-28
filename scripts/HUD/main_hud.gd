extends Control

@onready var lives_label: Label = $Container/Lives/HBoxContainer/LifeCount
@onready var time_left_count: Label = $Container/Time/HBoxContainer/Label
@onready var score_count: Label = $Container/Score/ScoreText
@onready var coin_count: Label = $Container/Score/Coins/Label
@onready var life_count: Control = $Container/Lives

func _ready() -> void:
	update_hud()

func _process(_delta: float) -> void:
	update_hud()

func update_hud() -> void:
	coin_count.text = str(GameManager.coins)
	score_count.text = str(GameManager.score)
	lives_label.text = str(GameManager.lives)
	time_left_count.text = str(GameManager.time)

	if GameManager.lives < 1:
		life_count.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		life_count.modulate = Color.WHITE

func _on_timer_timeout() -> void:
	if GameManager.time <= 0:
		return

	GameManager.time -= 1
