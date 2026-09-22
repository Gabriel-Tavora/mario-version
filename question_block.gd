extends InteractableBlock

@export var item_scene: PackedScene


func _trigger_effect(player: Player) -> void:
	if current_state == State.EMPTY:
		return

	# Som do bloco
	SoundManager.play_bump()

	current_state = State.EMPTY
	sprite.play("empty")

	if item_scene:
		var item = item_scene.instantiate()
		get_parent().add_child(item)

		item.global_position = global_position

		item.set_physics_process(false)

		var tween = create_tween()
		var target_position = global_position + Vector2(0, -16)

		tween.tween_property(
			item,
			"global_position",
			target_position,
			0.7
		)

		tween.tween_callback(func():
			item.set_physics_process(true)
		)
