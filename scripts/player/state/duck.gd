extends State

const DUST_VFX = preload("res://scenes/vfx/skid_smoke.tscn")
const DUCK_DECELERATION := 280.0

var vfx_timer: float = 0.0
const VFX_COOLDOWN := 0.1

func enter() -> void:
	player.animated_sprite.play("Crouch")
	player.standing_shape.disabled = true
	player.duck_shape.disabled = false
	vfx_timer = VFX_COOLDOWN

func exit() -> void:
	player.standing_shape.disabled = false
	player.duck_shape.disabled = true

func physics_update(delta: float) -> void:
	var dir := Input.get_axis("player_left", "player_right")

	if dir < 0:
		player.animated_sprite.flip_h = true
	elif dir > 0:
		player.animated_sprite.flip_h = false

	if not player.is_on_floor():
		if Input.is_action_just_released("player_jump") and player.velocity.y < 0:
			player.velocity.y *= 0.6

		if dir != 0:
			player.velocity.x = move_toward(
				player.velocity.x,
				dir * player.max_run_speed,
				player.air_acceleration * delta
			)
	else:
		player.velocity.x = move_toward(
			player.velocity.x,
			0.0,
			DUCK_DECELERATION * delta
		)

		if abs(player.velocity.x) >= 100.0:
			vfx_timer += delta

			if vfx_timer >= VFX_COOLDOWN:
				vfx_timer = 0.0

				var dust = DUST_VFX.instantiate()
				dust.position = player.position + Vector2(0, 15)
				dust.animation_finished.connect(dust.queue_free)
				player.get_tree().current_scene.add_child(dust)

		if Input.is_action_just_pressed("player_jump"):
			player.velocity.y = (
				player.SUPER_JUMP_VELOCITY
				if player.is_priming_jump
				else player.JUMP_VELOCITY
			)
			player.jump_sound.play()

	if not Input.is_action_pressed("player_duck") and player.is_on_floor():
		if abs(player.velocity.x) > 10:
			state_machine.change_state(state_machine.run)
		else:
			state_machine.change_state(state_machine.idle)
