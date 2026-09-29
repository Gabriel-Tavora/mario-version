extends State

const JUMP_CUT_MULTIPLIER := 0.6
const RUN_THRESHOLD := 50.0

func enter() -> void:
	_update_air_animation()

func physics_update(delta: float) -> void:
	if Input.is_action_just_pressed("player_duck") and not player.is_on_floor():
		state_machine.change_state(state_machine.ground_pound)
		return

	_handle_variable_jump()

	var dir := Input.get_axis("player_left", "player_right")
	_handle_air_movement(dir, delta)

	if _is_landed():
		_land(dir)
		return

	_update_air_animation()

func _handle_variable_jump() -> void:
	if Input.is_action_just_released("player_jump") and player.velocity.y < 0:
		player.velocity.y *= JUMP_CUT_MULTIPLIER

func _handle_air_movement(dir: float, delta: float) -> void:
	if dir != 0:
		player.velocity.x = move_toward(
			player.velocity.x,
			dir * player.max_run_speed,
			player.air_acceleration * delta
		)

		player.animated_sprite.flip_h = dir < 0

func _is_landed() -> bool:
	return player.is_on_floor() and player.velocity.y >= 0

func _land(dir: float) -> void:
	player.is_priming_jump = false

	if Input.is_action_pressed("player_duck"):
		state_machine.change_state(state_machine.duck)
	elif dir != 0 or abs(player.velocity.x) > RUN_THRESHOLD:
		state_machine.change_state(state_machine.run)
	else:
		state_machine.change_state(state_machine.idle)

func _update_air_animation() -> void:
	var anim := &"Jump" if player.velocity.y < 0 else &"Fall"

	if player.animated_sprite.animation != anim:
		player.animated_sprite.play(anim)
