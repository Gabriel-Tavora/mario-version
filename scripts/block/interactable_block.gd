extends AnimatableBody2D
class_name InteractableBlock

enum State {
	EMPTY,
	ACTIVE
}

var current_state = State.ACTIVE

@onready var sprite: AnimatedSprite2D = $Sprite


func hit_by_player(player: Player) -> void:
	print("Pai hit_by_player chamado! Estado atual: ", current_state)

	if current_state == State.EMPTY:
		print("Foi atingido, mas está vazio.")
		return

	print("Foi atingido.")

	bounce_animation()

	_trigger_effect(player)


func bounce_animation() -> void:
	var tween = create_tween()
	var start_y = position.y

	var original_scale = sprite.scale
	var peak_scale = original_scale * 1.2

	tween.tween_property(
		self,
		"position:y",
		start_y - 10,
		0.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Aumenta o tamanho do sprite durante o pulo.
	tween.parallel().tween_property(
		sprite,
		"scale",
		peak_scale,
		0.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Faz o bloco voltar para a posição original.
	tween.tween_property(
		self,
		"position:y",
		start_y,
		0.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Volta o sprite para o tamanho original.
	tween.parallel().tween_property(
		sprite,
		"scale",
		original_scale,
		0.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _trigger_effect(player: Player) -> void:
	pass
