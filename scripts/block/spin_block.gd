extends InteractableBlock
class_name SpinBlock

@onready var spin_scene = preload("res://scenes/blocks/spin_effect.tscn")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var spin_jump_area: Area2D = $SpinJumpArea

var is_spinning := false


func _ready() -> void:
	spin_jump_area.area_entered.connect(_on_spin_jump_area_area_entered)

func _trigger_effect(player: Player) -> void:
	# Interação normal: Mario bate por baixo
	_start_spin()


func _on_spin_jump_area_area_entered(area: Area2D) -> void:
	print("=== spin_jump_area entrada: ", area.name, " ===")

	if is_spinning:
		print("  -> rejeitado: já está girando")
		return

	var player := area.get_parent() as Player

	if player == null:
		print("  -> rejeitado: parent de '%s' não é Player (é: %s)" % [area.name, area.get_parent()])
		return

	print("  player encontrado: ", player.name)
	print("  player.y=%s block.y=%s" % [player.global_position.y, global_position.y])

	if player.global_position.y >= global_position.y:
		print("  -> rejeitado: player não está acima do bloco")
		return

	print("  current_state=%s spin_jump_state=%s" % [player.state_machine.current_state, player.state_machine.spin_jump])

	if player.state_machine.current_state != player.state_machine.spin_jump:
		print("  -> rejeitado: não está no estado Spin Jump")
		return

	print("  velocity.y=", player.velocity.y)

	if player.velocity.y <= 0:
		print("  -> rejeitado: não está descendo")
		return

	print("  -> TODOS OS GUARDS PASSARAM, iniciando bounce+spin")

	player.velocity.y = -200
	_start_spin()
func _start_spin() -> void:
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

	if is_instance_valid(spin):
		spin.queue_free()

	visible = true
	collision_shape.set_deferred("disabled", false)

	is_spinning = false
