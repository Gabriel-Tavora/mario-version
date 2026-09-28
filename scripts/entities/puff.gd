extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.visible = false

func play_puff() -> void:
	sprite.visible = true
	sprite.frame = 0
	sprite.play("puff")
	sprite.animation_finished.connect(queue_free)
