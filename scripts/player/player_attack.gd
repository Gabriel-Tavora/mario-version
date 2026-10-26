class_name PlayerAttack
extends Node
## Ataques do Mario: bola de fogo, martelo arremessado e martelo corpo a corpo.
## Nó filho do Player, chamado "Attack".

const FIREBALL_SCENE := preload("res://scenes/effects/player_fireball.tscn")
const HAMMER_THROW_SCENE := preload("res://scenes/effects/player_hammer.tscn")
const MAX_FIREBALLS := 2
const MAX_HAMMERS := 2

@export var fireball_offset := Vector2(12, 2)
@export var fireball_attack_time := 0.2
@export var hammer_offset := Vector2(8, -10)
@export var hammer_release_delay := 0.1
@export var hammer_attack_time := 0.35

@onready var player: Player = get_parent()

var _attack_animation := "Attack"
var _attack_anim_speed := 1.0
var _saved_frame := 0
var _saved_progress := 0.0


func handle_input() -> void:
	if player.is_dead or not Input.is_action_just_pressed(Player.ACTION_ATTACK):
		return
	match player.power_form:
		Player.PowerForm.FIRE:
			try_throw_fireball()
		Player.PowerForm.HAMMER:
			try_throw_hammer()


## Guarda o frame antes dos estados trocarem a animação
func save_frame() -> void:
	_saved_frame = player.animated_sprite.frame
	_saved_progress = player.animated_sprite.frame_progress


## Mantém a animação de ataque por cima da animação do estado
func apply_override() -> void:
	if not player.is_attacking:
		return
	var sprite := player.animated_sprite
	sprite.speed_scale = _attack_anim_speed
	if sprite.animation != _attack_animation:
		sprite.play(_attack_animation)
		sprite.set_frame_and_progress(_saved_frame, _saved_progress)


func play_attack_animation(animation_name: String, attack_time: float) -> void:
	var sprite := player.animated_sprite
	var frames := sprite.sprite_frames
	if not frames.has_animation(animation_name):
		return

	var total := 0.0
	for i in frames.get_frame_count(animation_name):
		total += frames.get_frame_duration(animation_name, i)

	var fps := frames.get_animation_speed(animation_name)
	var natural := total / fps if fps > 0.0 else attack_time

	_attack_anim_speed = maxf(natural / attack_time, 0.1)
	_attack_animation = animation_name
	player.is_attacking = true

	sprite.speed_scale = _attack_anim_speed
	sprite.play(animation_name)

	await get_tree().create_timer(attack_time).timeout

	player.is_attacking = false
	sprite.speed_scale = 1.0


func _facing() -> int:
	return -1 if player.animated_sprite.flip_h else 1


func try_throw_fireball() -> bool:
	if player.power_form != Player.PowerForm.FIRE or player.is_power_down or player.is_attacking:
		return false
	if get_tree().get_nodes_in_group("fireball").size() >= MAX_FIREBALLS:
		return false

	var scene: PackedScene = player.fireball_scene if player.fireball_scene != null else FIREBALL_SCENE
	var dir := _facing()

	var fb: Fireball = scene.instantiate()
	fb.player = player
	fb.direction = dir
	player.get_parent().add_child(fb)
	fb.global_position = player.global_position + Vector2(fireball_offset.x * dir, fireball_offset.y)

	play_attack_animation("Attack", fireball_attack_time)
	return true


func try_throw_hammer() -> void:
	if player.power_form != Player.PowerForm.HAMMER or player.is_power_down or player.is_attacking:
		return
	if get_tree().get_nodes_in_group("player_hammer").size() >= MAX_HAMMERS:
		return

	play_attack_animation("Throw", hammer_attack_time)

	await get_tree().create_timer(hammer_release_delay).timeout

	if player.power_form != Player.PowerForm.HAMMER or player.is_power_down or not player.is_attacking:
		return

	var dir := _facing()
	var h: PlayerHammer = HAMMER_THROW_SCENE.instantiate()
	h.player = player
	h.direction = dir
	player.get_parent().add_child(h)
	h.global_position = player.global_position + Vector2(hammer_offset.x * dir, hammer_offset.y)


# --- Martelo corpo a corpo ---

func spawn_hammer() -> void:
	if is_instance_valid(player.hammer) or player.hammer_power_scene == null:
		return
	player.hammer = player.hammer_power_scene.instantiate()
	player.add_child(player.hammer)
	player.hammer.setup(player, player.animated_sprite)


func remove_hammer() -> void:
	if is_instance_valid(player.hammer):
		player.hammer.cancel()
		player.hammer.queue_free()
	player.hammer = null


func can_use_hammer() -> bool:
	return player.power_form == Player.PowerForm.HAMMER and is_instance_valid(player.hammer) and not player.is_power_down


func try_hammer_attack() -> bool:
	if not can_use_hammer():
		return false
	return player.hammer.start_attack()
