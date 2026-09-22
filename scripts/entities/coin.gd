extends Node2D

@onready var area: Area2D = $Area2D
@onready var coin_sound: AudioStreamPlayer2D = $CoinSound


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		collect()


func collect() -> void:
	GameManager.coins += 1

	SoundManager.play_coin()

	queue_free()
