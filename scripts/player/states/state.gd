class_name PlayerState
extends Node
## Base de todos os estados do Mario.

var player: Player
var state_machine: PlayerStateMachine


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


## Se o Player deve aplicar gravidade neste estado
func can_apply_gravity() -> bool:
	return true


# --- Transições comuns ---

## Pulo normal ou giratório (respeita coyote time e buffer)
func try_jump() -> bool:
	if not player.can_jump():
		return false
	if player.wants_spin_jump():
		player.spin_jump()
		return true
	if player.wants_jump():
		player.jump()
		return true
	return false


## Segurou baixo no chão: agacha, ou desliza se estiver numa rampa
func try_duck() -> bool:
	if not Input.is_action_pressed(Player.ACTION_DUCK):
		return false
	if player.is_on_slope():
		state_machine.change_state(state_machine.slide)
	else:
		state_machine.change_state(state_machine.duck)
	return true


## Para onde ir ao tocar o chão
func land() -> void:
	if try_jump():
		return
	if try_duck():
		return
	if player.get_input_x() != 0.0 or absf(player.velocity.x) > 1.0:
		state_machine.change_state(state_machine.run)
	else:
		state_machine.change_state(state_machine.idle)
