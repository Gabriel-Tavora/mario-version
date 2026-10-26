extends PlayerState
## Andando / correndo no chão.

## Velocidade mínima para derrapar ao virar
@export var skid_min_speed := 10.0
## Ritmo da animação = |vel_x| / este valor (40 no arquivo de referência)
@export var anim_speed_divisor := 40.0


func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.change_state(state_machine.air)
		return
	if try_jump() or try_duck():
		return

	var input := player.get_input_x()

	# Virou contra o embalo → derrapa
	if input != 0.0 and signf(input) != signf(player.velocity.x) \
			and absf(player.velocity.x) >= skid_min_speed:
		state_machine.change_state(state_machine.skid)
		return

	player.ground_move(delta)
	player.update_facing()

	if input == 0.0 and absf(player.velocity.x) < 1.0:
		player.velocity.x = 0.0
		state_machine.change_state(state_machine.idle)
		return

	_update_animation()


## "Walk" até encher o medidor P; com ele cheio, a pose de disparada "Run".
## O ritmo da animação acompanha a velocidade (|vel_x| / 40), e dobra
## subindo rampa íngreme, igual ao arquivo de referência.
func _update_animation() -> void:
	var anim_speed := maxf(absf(player.velocity.x) / anim_speed_divisor, 0.2)
	if player.is_moving_up_slope() and player.get_slope_type() >= Player.SlopeType.STEEP:
		anim_speed *= 2.0

	if player.is_sprinting():
		player.play_anim("Run", "Walk", anim_speed)
	else:
		player.play_anim("Walk", "Run", anim_speed)
