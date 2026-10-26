extends PlayerState
## Morte (igual à antiga): pausa o jogo e a música, para no ar,
## dá o pulo da morte e cai atravessando tudo.

## Tempo parado antes do pulo da morte
@export var hang_time := 0.5
@export var death_jump_velocity := -300.0

var _hovering := true


func enter() -> void:
	_hovering = true

	# Pausa o resto do jogo; só o Mario continua
	get_tree().paused = true
	player.process_mode = Node.PROCESS_MODE_ALWAYS

	var bgm := player.get_node_or_null("../BGM")
	if bgm:
		bgm.set_deferred("stream_paused", true)

	player.velocity = Vector2.ZERO
	player.is_attacking = false

	# Atravessa o chão
	player.standing_shape.set_deferred("disabled", true)
	player.duck_shape.set_deferred("disabled", true)

	player.dead_sound.play()
	player.animated_sprite.speed_scale = 1.0
	player.animated_sprite.play("Dead")

	await get_tree().create_timer(hang_time).timeout
	if state_machine.current_state != self:
		return
	player.velocity.y = death_jump_velocity
	_hovering = false


func can_apply_gravity() -> bool:
	return not _hovering


func physics_update(_delta: float) -> void:
	player.velocity.x = 0.0
	if _hovering:
		player.velocity.y = 0.0
