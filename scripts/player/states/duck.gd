extends PlayerState
## Agachado no chão reto.


func enter() -> void:
	player.set_ducking(true)
	player.play_anim("Crouch", "Idle")


func exit() -> void:
	player.set_ducking(false)


func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.change_state(state_machine.air)
		return

	# Começou a escorregar numa rampa
	if player.is_on_slope():
		state_machine.change_state(state_machine.slide)
		return

	# Agachado vai freando (não anda)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.ground_friction * delta)

	# Soltou o baixo → levanta, se tiver espaço
	if not Input.is_action_pressed(Player.ACTION_DUCK) and player.can_stand_up():
		land()
		return

	if player.can_jump() and player.wants_jump() and player.can_stand_up():
		player.jump()
		return

	player.play_anim("Crouch", "Idle")
