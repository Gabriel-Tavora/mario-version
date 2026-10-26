extends PlayerState
## Derrapando ao virar correndo (igual ao Skid antigo).

## Intervalo entre as nuvens de fumaça
@export var smoke_interval := 0.1
## Duração máxima da derrapada
@export var max_skid_time := 0.5

var _skid_timer := 0.0
var _smoke_timer := 0.0


func enter() -> void:
	_skid_timer = 0.0
	_smoke_timer = smoke_interval  # primeira nuvem já no primeiro frame
	# Vira para o lado contrário do embalo
	player.animated_sprite.flip_h = player.velocity.x > 0.0
	player.skid_sound.play()
	player.play_anim("Skid", "Walk")


func exit() -> void:
	player.skid_sound.stop()


func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.get_skid_decel() * delta)
	_skid_timer += delta

	# Fumaça nos pés
	_smoke_timer += delta
	if _smoke_timer >= smoke_interval:
		_smoke_timer = 0.0
		player.spawn_skid_smoke()

	var input := player.get_input_x()

	# Voltou para o lado do embalo → volta a correr
	if input != 0.0 and signf(input) == signf(player.velocity.x):
		state_machine.change_state(state_machine.run)
		return

	if not player.is_on_floor():
		state_machine.change_state(state_machine.air)
		return

	# Pulo saindo da derrapada (já sai virado)
	if player.can_jump() and player.wants_jump():
		player.update_facing()
		player.jump()
		return

	player.play_anim("Skid", "Walk")

	# Acabou o tempo ou parou → decide o próximo estado
	if _skid_timer >= max_skid_time or player.velocity.x == 0.0:
		land()
