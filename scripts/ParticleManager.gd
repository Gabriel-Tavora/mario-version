extends Node

const GROUND_POUND_IMPACT = preload("res://scenes/effects/ground_pound_impact.tscn")

const _4_PART_BREAK_PARTICLE = preload("res://scenes/blocks/4_part_break_particle.tscn")

func summon_particle(particle: PackedScene, position := Vector2.ZERO) -> void:
	await get_tree().process_frame
	var node = particle.instantiate()
	node.global_position = position
	get_tree().current_scene.add_child(node)

func summon_four_part(textures = [], position := Vector2.ZERO, texture_size := 16) -> void:
	await get_tree().process_frame
	var node = _4_PART_BREAK_PARTICLE.instantiate()
	node.sprite_size = texture_size
	node.global_position = position
	node.textures = textures
	get_tree().current_scene.add_child(node)
