extends State

const SKID_SPEED_THRESHOLD := 80.0

func enter() -> void:
	pass

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.change_state(state_machine.air)
		return

	if Input.is_action_just_pressed("player_spin_jump"):
		state_machine.change_state(state_machine.spin_jump)
		return

	if Input.is_action_just_pressed("player_jump"):
		player.is_priming_jump = (abs(player.velocity.x) >= 160.0)
		player.velocity.y = player.SUPER_JUMP_VELOCITY if player.is_priming_jump else player.JUMP_VELOCITY
		player.jump_sound.play()
		state_machine.change_state(state_machine.air)
		return

	if Input.is_action_pressed("player_duck"):
		state_machine.change_state(state_machine.duck)
		return

	var dir := Input.get_axis("player_left", "player_right")

	if player.velocity.x == 0 and dir == 0:
		state_machine.change_state(state_machine.idle)
		return

	# Mudança brusca de direção
	if dir != 0 and abs(player.velocity.x) >= SKID_SPEED_THRESHOLD and sign(player.velocity.x) != sign(dir):
		state_machine.change_state(state_machine.skid)
		return

	# Acelera gradualmente até a velocidade máxima
	player.velocity.x = move_toward(
		player.velocity.x,
		dir * player.max_run_speed,
		player.ground_acceleration * delta
	)

	# Direção do sprite
	if dir < 0:
		player.animated_sprite.flip_h = true
	elif dir > 0:
		player.animated_sprite.flip_h = false

	# Animação acompanha a velocidade
	var speed_ratio: float = abs(player.velocity.x) / player.max_run_speed

	if abs(player.velocity.x) >= player.max_walk_speed:
		player.animated_sprite.play("Run")
	else:
		player.animated_sprite.play("Walk")

	player.animated_sprite.speed_scale = lerp(0.6, 3.0, speed_ratio)
