extends State

func enter() -> void:
	player.animated_sprite.play("Spin")
	player.animated_sprite.speed_scale = 1.0
	player.velocity.y = player.SPIN_JUMP_VELOCITY
	player.spin_jump_sound.play()

func exit() -> void:
	player.animated_sprite.speed_scale = 1.0

func physics_update(delta: float) -> void:
	if Input.is_action_just_released("player_jump") and player.velocity.y < 0:
		player.velocity.y *= 0.6

	var dir := Input.get_axis("player_left", "player_right")
	var max_speed := player.max_run_speed if Input.is_action_pressed("player_run") else player.max_walk_speed

	if dir != 0:
		player.velocity.x = move_toward(
			player.velocity.x,
			dir * max_speed,
			player.air_acceleration * delta
		)

		if dir < 0:
			player.animated_sprite.flip_h = true
		elif dir > 0:
			player.animated_sprite.flip_h = false
	else:
		player.velocity.x = move_toward(
			player.velocity.x,
			0.0,
			player.air_acceleration * 0.1 * delta
		)

	if not player.is_on_floor():
		return

	player.is_priming_jump = false

	if Input.is_action_pressed("player_duck"):
		state_machine.change_state(state_machine.duck)
		return

	if dir != 0:
		state_machine.change_state(state_machine.run)
		return

	if abs(player.velocity.x) > 50:
		state_machine.change_state(state_machine.run)
	else:
		state_machine.change_state(state_machine.idle)
