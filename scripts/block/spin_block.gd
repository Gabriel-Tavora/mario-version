extends InteractableBlock
class_name SpinBlock

@onready var spin_scene = preload("res://scenes/blocks/spin_effect.tscn")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_spinning := false


func _trigger_effect(player: Player) -> void:
	if is_spinning:
		return

	is_spinning = true

	visible = false

	collision_shape.set_deferred("disabled", true)

	SoundManager.play_bump()

	var spin = spin_scene.instantiate()
	get_parent().add_child(spin)

	spin.global_position = global_position

	var animated_sprite: AnimatedSprite2D = spin.get_node("AnimatedSprite2D")
	animated_sprite.play("spin")

	await get_tree().create_timer(5.0).timeout

	spin.queue_free()

	visible = true

	collision_shape.set_deferred("disabled", false)

	is_spinning = false
