class_name Player
extends CharacterBody2D

enum PowerForm { SMALL, SUPER, FIRE, HAMMER }

@onready var state_machine: Node = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var duck_shape: CollisionShape2D = $DuckShape
@onready var standing_shape: CollisionShape2D = $StandingShape
@onready var klock_sound: AudioStreamPlayer2D = $Sound/KlockSound
@onready var jump_sound: AudioStreamPlayer2D = $Sound/JumpSound
@onready var skid_sound: AudioStreamPlayer2D = $Sound/SkidSound
@onready var dead_sound: AudioStreamPlayer2D = $Sound/DeadSound
@onready var spin_jump_sound: AudioStreamPlayer2D = $Sound/SpinJumpSound
@onready var powerup_sound: AudioStreamPlayer2D = $Sound/PowerupSound

@export var small_sprite_frames_new: SpriteFrames
@export var super_sprite_frames: SpriteFrames
@export var fire_sprite_frames: SpriteFrames
@export var hammer_sprite_frames: SpriteFrames
@export var hammer_power_scene: PackedScene
@export var fireball_scene: PackedScene

const FIREBALL_SCENE := preload("res://scenes/effects/player_fireball.tscn")
const MAX_FIREBALLS := 2
@export var fireball_offset := Vector2(12, 2)
@export var fireball_attack_time := 0.2

const HAMMER_THROW_SCENE := preload("res://scenes/effects/player_hammer.tscn")
const MAX_HAMMERS := 2
@export var hammer_offset := Vector2(8, -10)
@export var hammer_release_delay := 0.1
@export var hammer_attack_time := 0.35

var hammer: Hammer = null

var small_sprite_frames: SpriteFrames
var power_form: PowerForm = PowerForm.SMALL

var ground_acceleration := 100.0
var max_walk_speed := 78.0
var max_run_speed := 180.0

var air_acceleration := 400.0
var max_fall_speed := 258.0

const JUMP_VELOCITY = -360.0
const SUPER_JUMP_VELOCITY = -430.0
const SPIN_JUMP_VELOCITY = -280.0
@export var gravity: float = 900.0

var is_priming_jump := false
var is_invulnerable := false
var is_power_down := false

var is_attacking := false
var _attack_animation := "Attack"
var _attack_anim_speed := 1.0

const POWERUP_SCORE := 1000
var is_dead := false
func _register_powerup(item: String) -> void:
	GameManager.score += POWERUP_SCORE
	GameManager.set_item_box(item)

func _ready() -> void:
	small_sprite_frames = animated_sprite.sprite_frames
	animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT
	powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	state_machine.init(self)


func die() -> void:
	if is_invulnerable or is_dead:
		return

	if is_instance_valid(hammer):
		hammer.cancel()

	if power_form != PowerForm.SMALL:
		power_down()
		return

	is_dead = true
	GameManager.on_player_died()

	velocity = Vector2.ZERO
	state_machine.change_state(state_machine.dead)

func power_down() -> void:
	if is_power_down:
		return

	is_power_down = true
	is_invulnerable = true
	is_attacking = false
	velocity = Vector2.ZERO

	if is_instance_valid(hammer):
		hammer.cancel()

	var next_form := PowerForm.SMALL if power_form == PowerForm.SUPER else PowerForm.SUPER

	animated_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	animated_sprite.speed_scale = 1.0

	get_tree().paused = true

	var frames := animated_sprite.sprite_frames
	var hurt_anim := ""

	if frames.has_animation("Damage"):
		hurt_anim = "Damage"
	elif frames.has_animation("Shrink"):
		hurt_anim = "Shrink"

	powerup_sound.play()

	if hurt_anim != "":
		animated_sprite.play(hurt_anim)
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.3, true).timeout

	set_form(next_form)

	get_tree().paused = false
	animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT

	for i in 6:
		animated_sprite.visible = false
		await get_tree().create_timer(0.08, true).timeout
		animated_sprite.visible = true
		await get_tree().create_timer(0.08, true).timeout

	animated_sprite.visible = true
	is_invulnerable = false
	is_power_down = false


func bounce() -> void:
	is_priming_jump = Input.is_action_pressed("player_jump")

	velocity.y = JUMP_VELOCITY * 1.0 if is_priming_jump else JUMP_VELOCITY * 0.6
	klock_sound.play()

	state_machine.change_state(state_machine.air)


func set_form(form: PowerForm) -> void:
	if form == power_form:
		return

	if power_form == PowerForm.HAMMER:
		_remove_hammer()

	is_attacking = false
	animated_sprite.speed_scale = 1.0
	power_form = form

	match form:
		PowerForm.SMALL:
			animated_sprite.sprite_frames = small_sprite_frames_new
			standing_shape.position = Vector2(0, 7.5)
			standing_shape.shape.size = Vector2(12, 15)
			animated_sprite.play("Idle")

		PowerForm.SUPER:
			animated_sprite.sprite_frames = super_sprite_frames
			standing_shape.position = Vector2(0, 0)
			standing_shape.shape.size = Vector2(16, 30)
			animated_sprite.play("Idle")

		PowerForm.FIRE:
			animated_sprite.sprite_frames = fire_sprite_frames
			standing_shape.position = Vector2(0, 0)
			standing_shape.shape.size = Vector2(16, 30)
			animated_sprite.play("Idle")

		PowerForm.HAMMER:
			animated_sprite.sprite_frames = hammer_sprite_frames
			standing_shape.position = Vector2(0, 0)
			standing_shape.shape.size = Vector2(16, 30)
			animated_sprite.play("Idle")
			_spawn_hammer()


func _play_attack_animation(animation_name: String, attack_time: float) -> void:
	var frames := animated_sprite.sprite_frames

	if not frames.has_animation(animation_name):
		return

	var total: float = 0.0

	for i in frames.get_frame_count(animation_name):
		total += frames.get_frame_duration(animation_name, i)

	var fps: float = frames.get_animation_speed(animation_name)
	var natural: float = total / fps if fps > 0.0 else attack_time

	_attack_anim_speed = maxf(natural / attack_time, 0.1)
	_attack_animation = animation_name
	is_attacking = true

	animated_sprite.speed_scale = _attack_anim_speed
	animated_sprite.play(animation_name)

	await get_tree().create_timer(attack_time).timeout

	is_attacking = false
	animated_sprite.speed_scale = 1.0


func try_throw_fireball() -> bool:
	if power_form != PowerForm.FIRE or is_power_down or is_attacking:
		return false

	if get_tree().get_nodes_in_group("fireball").size() >= MAX_FIREBALLS:
		return false

	var scene: PackedScene = fireball_scene if fireball_scene != null else FIREBALL_SCENE
	var dir := -1 if animated_sprite.flip_h else 1

	var fb: Fireball = scene.instantiate()
	fb.player = self
	fb.direction = dir

	get_parent().add_child(fb)
	fb.global_position = global_position + Vector2(fireball_offset.x * dir, fireball_offset.y)

	_play_attack_animation("Attack", fireball_attack_time)

	return true


func try_throw_hammer() -> void:
	if power_form != PowerForm.HAMMER or is_power_down or is_attacking:
		return

	if get_tree().get_nodes_in_group("player_hammer").size() >= MAX_HAMMERS:
		return

	_play_attack_animation("Throw", hammer_attack_time)

	await get_tree().create_timer(hammer_release_delay).timeout

	if power_form != PowerForm.HAMMER or is_power_down or not is_attacking:
		return

	var dir := -1 if animated_sprite.flip_h else 1

	var h: PlayerHammer = HAMMER_THROW_SCENE.instantiate()
	h.player = self
	h.direction = dir

	get_parent().add_child(h)
	h.global_position = global_position + Vector2(hammer_offset.x * dir, hammer_offset.y)


func _spawn_hammer() -> void:
	if is_instance_valid(hammer) or hammer_power_scene == null:
		return

	hammer = hammer_power_scene.instantiate()
	add_child(hammer)
	hammer.setup(self, animated_sprite)


func _remove_hammer() -> void:
	if is_instance_valid(hammer):
		hammer.cancel()
		hammer.queue_free()

	hammer = null


func can_use_hammer() -> bool:
	return power_form == PowerForm.HAMMER and is_instance_valid(hammer) and not is_power_down


func try_hammer_attack() -> bool:
	if not can_use_hammer():
		return false

	return hammer.start_attack()


func can_collect_hammer() -> bool:
	return (power_form == PowerForm.SMALL or power_form == PowerForm.SUPER) and not is_power_down


func can_collect_fire_flower() -> bool:
	return (power_form == PowerForm.SMALL or power_form == PowerForm.SUPER) and not is_power_down


func collect_hammer() -> void:
	_register_powerup("hammer") 
	if not can_collect_hammer():
		return
	if animated_sprite.sprite_frames.has_animation("GrowHammer"):
		animated_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		animated_sprite.speed_scale = 1.0

		get_tree().paused = true
		animated_sprite.play("GrowHammer")

		SoundManager.play_hammer_transformation()

		await animated_sprite.animation_finished

		get_tree().paused = false
		animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		SoundManager.play_hammer_transformation()

	set_form(PowerForm.HAMMER)


func collect_mushroom() -> void:
	_register_powerup("mushroom")
	if power_form != PowerForm.SMALL:
		return

	await grow_animation()

	if power_form == PowerForm.SMALL:
		set_form(PowerForm.SUPER)


func grow_animation() -> void:
	animated_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	animated_sprite.speed_scale = 1.0

	powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true

	animated_sprite.play("Grow")
	powerup_sound.play()

	await animated_sprite.animation_finished

	get_tree().paused = false
	animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT


func collect_fire_flower() -> void:
	_register_powerup("fire_flower")
	if not can_collect_fire_flower():
		return
	if animated_sprite.sprite_frames.has_animation("GrowFire"):
		animated_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		animated_sprite.speed_scale = 1.0
		powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS

		get_tree().paused = true
		animated_sprite.play("GrowFire")
		powerup_sound.play()

		await animated_sprite.animation_finished

		get_tree().paused = false
		animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		powerup_sound.play()

	set_form(PowerForm.FIRE)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("player_attack"):
		match power_form:
			PowerForm.FIRE:
				try_throw_fireball()
			PowerForm.HAMMER:
				try_throw_hammer()

	var attack_frame := animated_sprite.frame
	var attack_progress := animated_sprite.frame_progress

	state_machine.process_physics(delta)

	if is_attacking:
		animated_sprite.speed_scale = _attack_anim_speed

		if animated_sprite.animation != _attack_animation:
			animated_sprite.play(_attack_animation)
			animated_sprite.set_frame_and_progress(attack_frame, attack_progress)

	_attempt_correction(delta, 2)

	if not is_on_floor() and state_machine.current_state.can_apply_gravity():
		velocity.y += gravity * delta
		velocity.y = minf(velocity.y, max_fall_speed)

	move_and_slide()

	if is_on_ceiling():
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			var collider = col.get_collider()

			if collider is InteractableBlock:
				if col.get_normal().y > 0.5:
					velocity.y = 10.0
					collider.hit_by_player(self)
					break


func _attempt_correction(delta: float, amount: int) -> void:
	if (
		velocity.y < 0
		and test_move(global_transform, Vector2(0, velocity.y * delta))
	):
		for i in range(1, amount * 2 + 1):
			for j in [-1.0, 1.0]:
				if not test_move(
					global_transform.translated(Vector2(i * j / 2, 0)),
					Vector2(0, velocity.y * delta)
				):
					translate(Vector2(i * j / 2, 0))

					if velocity.x * j / 2 < 0:
						velocity.x = 0

					return
