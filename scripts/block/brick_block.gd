extends InteractableBlock
class_name BrickBlock

const FOUR_PART_BREAK = preload("res://scenes/blocks/4_part_break_particle.tscn")
const BRICK_BREAK = preload("res://textures/Sprites/Particles/BrickBreak.png")

var can_break := true


func _trigger_effect(player: Player) -> void:
	if player.power_form == Player.PowerForm.SUPER:
		break_block()
	else:
		SoundManager.play_shatter()


func break_block() -> void:
	if not can_break:
		return

	can_break = false

	SoundManager.play_shatter()

	var break_effect = FOUR_PART_BREAK.instantiate()
	break_effect.global_position = global_position
	break_effect.textures = [
		BRICK_BREAK,
		BRICK_BREAK,
		BRICK_BREAK,
		BRICK_BREAK
	]

	get_tree().current_scene.add_child(break_effect)

	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	queue_free()
