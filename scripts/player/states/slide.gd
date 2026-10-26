extends PlayerState
## Deslizando numa rampa (segurou baixo em superfície inclinada).

## Intervalo entre as nuvens de fumaça
@export var smoke_interval := 0.12
## Velocidade mínima para soltar fumaça
@export var smoke_min_speed := 60.0

var _smoke_timer := 0.0


func enter() -> void:
	_smoke_timer = 0.0
	player.is_sliding = true
	player.set_ducking(true)
	player.play_anim("Slide", "Crouch")


func exit() -> void:
	player.is_sliding = false
	player.set_ducking(false)


func physics_update(delta: float) -> void:
	# Saiu da beirada deslizando: mantém o embalo no ar
	if not player.is_on_floor():
		state_machine.change_state(state_machine.air)
		return

	# Pulo cancela o slide (sai com a velocidade do slide)
	if player.can_jump() and player.wants_jump() and player.can_stand_up():
		player.jump()
		return

	var slope := player.get_slope_dir()
	if slope != 0.0:
		# Acelera morro abaixo
		player.velocity.x = move_toward(
			player.velocity.x, slope * player.slide_max_speed, player.get_slide_accel() * delta)
		player.animated_sprite.flip_h = slope < 0.0
	else:
		# Chão reto: vai freando
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.slide_friction * delta)

	player.play_anim("Slide", "Crouch")

	# Fumaça enquanto desliza rápido
	_smoke_timer -= delta
	if _smoke_timer <= 0.0 and absf(player.velocity.x) > smoke_min_speed:
		_smoke_timer = smoke_interval
		player.spawn_skid_smoke()

	# Parou no chão reto
	if slope == 0.0 and absf(player.velocity.x) < 5.0 and player.can_stand_up():
		player.velocity.x = 0.0
		land()
