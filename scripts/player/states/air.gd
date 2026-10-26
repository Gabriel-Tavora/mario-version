extends PlayerState
## No ar: pulo normal ou caindo.

var _run_jump := false


func enter() -> void:
	# Pulou em disparada (medidor P cheio) → animação de pulo correndo, como no SMW
	_run_jump = player.velocity.y < 0.0 and player.is_sprinting()


func physics_update(delta: float) -> void:
	if player.is_on_floor() and player.velocity.y >= 0.0:
		land()
		return

	# Pulo com coyote time (acabou de sair da beirada)
	if try_jump():
		return

	# Baixo no ar → ground pound
	if Input.is_action_just_pressed(Player.ACTION_DUCK):
		state_machine.change_state(state_machine.ground_pound)
		return

	player.air_move(delta)
	player.update_facing()

	if _run_jump:
		player.play_anim("RunJump", "Jump")
	elif player.velocity.y < 0.0:
		player.play_anim("Jump")
	else:
		player.play_anim("Fall", "Jump")
