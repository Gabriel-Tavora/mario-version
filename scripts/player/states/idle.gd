extends PlayerState
## Parado no chão.


func enter() -> void:
	player.play_anim("Idle")


func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.change_state(state_machine.air)
		return
	if try_jump() or try_duck():
		return

	player.ground_move(delta)
	player.update_facing()

	# Apertou um lado, ou está escorregando numa rampa íngreme
	if player.get_input_x() != 0.0 or absf(player.velocity.x) > 10.0:
		state_machine.change_state(state_machine.run)
		return

	player.play_anim("Idle")
