extends PlayerState
## Pulo giratório (precisa da ação "player_spin" no Mapa de Entrada).


func enter() -> void:
	player.play_anim("Spin", "Jump")


func physics_update(delta: float) -> void:
	if player.is_on_floor() and player.velocity.y >= 0.0:
		land()
		return

	player.air_move(delta)
	player.play_anim("Spin", "Jump")
