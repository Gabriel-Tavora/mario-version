class_name Player
extends CharacterBody2D

enum PowerForm { SMALL, SUPER, FIRE }

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

func die() -> void:
	if is_invulnerable:
		return

	if power_form == PowerForm.SUPER:
		power_down()
		return

	velocity = Vector2.ZERO
	state_machine.change_state(state_machine.dead)

func power_down() -> void:
	if is_power_down:
		return

	is_power_down = true
	is_invulnerable = true
	velocity = Vector2.ZERO

	animated_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	animated_sprite.speed_scale = 1.0

	get_tree().paused = true

	animated_sprite.play("Shrink")
	powerup_sound.play()

	await animated_sprite.animation_finished

	set_form(PowerForm.SMALL)

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

func _ready() -> void:
	small_sprite_frames = animated_sprite.sprite_frames
	animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT
	powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	state_machine.init(self)

func set_form(form: PowerForm) -> void:
	if form == power_form:
		return

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

func collect_mushroom() -> void:
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

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)
	_attempt_correction(delta, 2)

	if not is_on_floor() and state_machine.current_state.can_apply_gravity():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

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


func collect_fire_flower() -> void:
	if power_form == PowerForm.FIRE:
		return

	animated_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	animated_sprite.speed_scale = 1.0
	powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS

	match power_form:
		PowerForm.SMALL:
			animated_sprite.sprite_frames = small_sprite_frames_new
		PowerForm.SUPER:
			animated_sprite.sprite_frames = super_sprite_frames

	print("FORM: ", power_form)
	print("SPRITE FRAMES: ", animated_sprite.sprite_frames)
	print("ANIMATIONS: ", animated_sprite.sprite_frames.get_animation_names())
	print("SMALL: ", small_sprite_frames_new.get_animation_names())
	print("SUPER: ", super_sprite_frames.get_animation_names())
	print("FIRE: ", fire_sprite_frames.get_animation_names())
	get_tree().paused = true

	animated_sprite.play("GrowFire")
	powerup_sound.play()

	await animated_sprite.animation_finished

	get_tree().paused = false
	animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT

	set_form(PowerForm.FIRE)
