class_name PlayerPowers
extends Node
## Power-ups do Mario: troca de forma, crescer, levar dano.
## Nó filho do Player, chamado "Powers".

@onready var player: Player = get_parent()


func _register_powerup(item: String) -> void:
	GameManager.score += Player.POWERUP_SCORE
	GameManager.set_item_box(item)


func set_form(form: Player.PowerForm) -> void:
	if form == player.power_form:
		return

	GameManager.player_form = form
	if player.power_form == Player.PowerForm.HAMMER:
		player.attack.remove_hammer()

	var sprite := player.animated_sprite
	var shape := player.standing_shape.shape as RectangleShape2D

	player.is_attacking = false
	sprite.speed_scale = 1.0
	player.power_form = form

	match form:
		Player.PowerForm.SMALL:
			sprite.sprite_frames = player.small_sprite_frames_new
			player.standing_shape.position = Vector2(0, 7.5)
			shape.size = Vector2(12, 15)
		Player.PowerForm.SUPER:
			sprite.sprite_frames = player.super_sprite_frames
			player.standing_shape.position = Vector2(0, 0)
			shape.size = Vector2(16, 30)
		Player.PowerForm.FIRE:
			sprite.sprite_frames = player.fire_sprite_frames
			player.standing_shape.position = Vector2(0, 0)
			shape.size = Vector2(16, 30)
		Player.PowerForm.HAMMER:
			sprite.sprite_frames = player.hammer_sprite_frames
			player.standing_shape.position = Vector2(0, 0)
			shape.size = Vector2(16, 30)
			player.attack.spawn_hammer()

	sprite.play("Idle")


func power_down() -> void:
	if player.is_power_down:
		return

	var sprite := player.animated_sprite

	player.is_power_down = true
	player.is_invulnerable = true
	player.is_attacking = false
	player.velocity = Vector2.ZERO

	if is_instance_valid(player.hammer):
		player.hammer.cancel()

	var next_form := Player.PowerForm.SMALL if player.power_form == Player.PowerForm.SUPER else Player.PowerForm.SUPER

	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	player.powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.speed_scale = 1.0

	get_tree().paused = true

	var frames := sprite.sprite_frames
	var hurt_anim := ""
	if frames.has_animation("Damage"):
		hurt_anim = "Damage"
	elif frames.has_animation("Shrink"):
		hurt_anim = "Shrink"

	player.powerup_sound.play()

	if hurt_anim != "":
		sprite.play(hurt_anim)
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.3, true).timeout

	set_form(next_form)

	get_tree().paused = false
	sprite.process_mode = Node.PROCESS_MODE_INHERIT

	# Pisca invulnerável
	for i in 6:
		sprite.visible = false
		await get_tree().create_timer(0.08, true).timeout
		sprite.visible = true
		await get_tree().create_timer(0.08, true).timeout

	sprite.visible = true
	player.is_invulnerable = false
	player.is_power_down = false


func grow_animation() -> void:
	await _play_paused_animation("Grow", true)


func can_collect_hammer() -> bool:
	return _is_small_or_super() and not player.is_power_down


func can_collect_fire_flower() -> bool:
	return _is_small_or_super() and not player.is_power_down


func collect_mushroom() -> void:
	_register_powerup("mushroom")
	if player.power_form != Player.PowerForm.SMALL:
		return

	await grow_animation()

	if player.power_form == Player.PowerForm.SMALL:
		set_form(Player.PowerForm.SUPER)


func collect_fire_flower() -> void:
	_register_powerup("fire_flower")
	if not can_collect_fire_flower():
		return

	if player.animated_sprite.sprite_frames.has_animation("GrowFire"):
		await _play_paused_animation("GrowFire", true)
	else:
		player.powerup_sound.play()

	set_form(Player.PowerForm.FIRE)


func collect_hammer() -> void:
	_register_powerup("hammer")
	if not can_collect_hammer():
		return

	if player.animated_sprite.sprite_frames.has_animation("GrowHammer"):
		SoundManager.play_hammer_transformation()
		await _play_paused_animation("GrowHammer", false)
	else:
		SoundManager.play_hammer_transformation()

	set_form(Player.PowerForm.HAMMER)


## Pausa o jogo, toca a animação e despausa.
func _play_paused_animation(anim_name: String, with_powerup_sound: bool) -> void:
	var sprite := player.animated_sprite

	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.speed_scale = 1.0
	player.powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true
	sprite.play(anim_name)
	if with_powerup_sound:
		player.powerup_sound.play()

	await sprite.animation_finished

	get_tree().paused = false
	sprite.process_mode = Node.PROCESS_MODE_INHERIT


func _is_small_or_super() -> bool:
	return player.power_form == Player.PowerForm.SMALL or player.power_form == Player.PowerForm.SUPER
