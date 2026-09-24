class_name CoinJump
extends Entity

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var particles: AnimatedSprite2D = $Particles

@export var move_distance := 32.0
@export var move_duration := 0.25


func _ready() -> void:
	animated_sprite.play("default")
	particles.visible = false


func start_coin_jump() -> void:
	var tween := create_tween()

	var target_position := global_position + Vector2(0, -move_distance)

	tween.tween_property(
		self,
		"global_position",
		target_position,
		move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(_collect_coin)


func _collect_coin() -> void:
	GameManager.coins += 1
	SoundManager.play_coin()

	animated_sprite.visible = false
	particles.visible = true

	particles.animation_finished.connect(_on_particles_finished)
	particles.play("particles")
	
func _on_particles_finished() -> void:
	queue_free()
