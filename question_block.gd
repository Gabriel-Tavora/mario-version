extends InteractableBlock

@export var item_scene: PackedScene

const DEFAULT_ITEM_SCENE := preload("res://scenes/entities/coin_jump.tscn")

func _trigger_effect(player: Player) -> void:
	if current_state == State.EMPTY:
		return

	SoundManager.play_bump()
	current_state = State.EMPTY
	sprite.play("empty")

	var scene_to_spawn := item_scene

	if scene_to_spawn == null:
		scene_to_spawn = DEFAULT_ITEM_SCENE

	var item = scene_to_spawn.instantiate()

	if item == null:
		return

	get_parent().add_child(item)
	item.global_position = global_position

	if item is CoinJump:
		item.start_coin_jump()
		return

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
		if is_instance_valid(item):
			item.set_physics_process(true))
