class_name Player
extends CharacterBody2D
## Núcleo do Mario: física, pulo, rampas e funções usadas pelos estados.
##
## Power-ups  -> Powers (player_powers.gd)
## Ataques    -> Attack (player_attack.gd)
## Movimento  -> StateMachine + estados (states/)

enum PowerForm { SMALL, SUPER, FIRE, HAMMER }

const ACTION_LEFT := "player_left"
const ACTION_RIGHT := "player_right"
const ACTION_JUMP := "player_jump"
const ACTION_DUCK := "player_duck"
const ACTION_RUN := "player_run"
const ACTION_ATTACK := "player_attack"
const ACTION_SPIN := "player_spin" # crie no Mapa de Entrada para usar o SpinJump

const POWERUP_SCORE := 1000

## Pulinho ao pisar em inimigo (SMW: $D0 soltando / $A8 segurando pulo)
const BOUNCE_LOW := 180.0
const BOUNCE_HIGH := 330.0

enum SlopeType { FLAT, GRADUAL, NORMAL, STEEP, VERY_STEEP }

## Velocidades em rampas: [descendo, subindo]
const WALK_SLOPE_SPEEDS := {
	SlopeType.GRADUAL: [75.0, 75.0],
	SlopeType.NORMAL: [90.0, 63.75],
	SlopeType.STEEP: [135.0, 56.25],
	SlopeType.VERY_STEEP: [135.0, 0.0],
}
const RUN_SLOPE_SPEEDS := {
	SlopeType.GRADUAL: [135.0, 135.0],
	SlopeType.NORMAL: [135.0, 116.75],
	SlopeType.STEEP: [135.0, 61.0],
	SlopeType.VERY_STEEP: [135.0, 0.0],
}
## Parado numa rampa, escorrega até esta velocidade
const STAND_SLOPE_SLIDE := {
	SlopeType.FLAT: 0.0,
	SlopeType.GRADUAL: 0.0,
	SlopeType.NORMAL: 0.0,
	SlopeType.STEEP: 60.0,
	SlopeType.VERY_STEEP: 120.0,
}
## Aceleração do slide por inclinação (px/s²)
const SLIDE_ACCELS := {
	SlopeType.FLAT: 0.0,
	SlopeType.GRADUAL: 112.5,
	SlopeType.NORMAL: 225.0,
	SlopeType.STEEP: 337.5,
	SlopeType.VERY_STEEP: 562.5,
}

# --- Nós ---
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var powers: PlayerPowers = $Powers
@onready var attack: PlayerAttack = $Attack
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var duck_shape: CollisionShape2D = $DuckShape
@onready var standing_shape: CollisionShape2D = $StandingShape
@onready var klock_sound: AudioStreamPlayer2D = $Sound/KlockSound
@onready var jump_sound: AudioStreamPlayer2D = $Sound/JumpSound
@onready var skid_sound: AudioStreamPlayer2D = $Sound/SkidSound
@onready var dead_sound: AudioStreamPlayer2D = $Sound/DeadSound
@onready var spin_jump_sound: AudioStreamPlayer2D = $Sound/SpinJumpSound
@onready var powerup_sound: AudioStreamPlayer2D = $Sound/PowerupSound

# --- Recursos (ficam aqui para não perder o que já está no Inspector) ---
@export var small_sprite_frames_new: SpriteFrames
@export var super_sprite_frames: SpriteFrames
@export var fire_sprite_frames: SpriteFrames
@export var hammer_sprite_frames: SpriteFrames
@export var hammer_power_scene: PackedScene
@export var fireball_scene: PackedScene

## Valores do Super Mario World. O arquivo de referência usa valores por
## frame (60 FPS); aqui estão convertidos para por segundo (x60).
@export_group("Movimento")
## Andar
@export var walk_speed := 75.0
## Correr (segurando Shift)
@export var run_speed := 135.0
## Disparada com o medidor P cheio
@export var sprint_speed := 180.0
## Aceleração no chão (5.265/frame)
@export var ground_accel := 315.9
## Atrito ao soltar o direcional no chão (3/frame)
@export var ground_friction := 180.0
## Virar andando (9.375/frame)
@export var skid_decel := 562.5
## Virar correndo (18.75/frame)
@export var skid_decel_run := 1125.0
## Aceleração no ar (5.265/frame). No ar, soltar o direcional NÃO freia.
@export var air_accel := 315.9
## Virar no ar andando / correndo
@export var air_skid_decel := 562.5
@export var air_skid_decel_run := 1125.0
## Gravidade sem segurar pulo
@export var gravity: float = 1350.0
## Gravidade segurando o pulo (subindo ou caindo)
@export var gravity_hold: float = 675.0
## Queda máxima
@export var max_fall_speed := 240.0

@export_group("Pulo")
## Pulo = -(base + incremento x (|vel_x| / 30))
@export var jump_base := 300.0
@export var jump_incr := 6.96
@export var spin_jump_base := 266.25
@export var spin_jump_incr := 7.5

@export_group("Medidor P")
## Medidor cheio
@export var p_meter_max := 112.0
## Enche +2 por frame correndo rápido (= 120/s, cheio em ~0,93 s)
@export var p_meter_fill := 120.0
## Esvazia -1 por frame (= 60/s)
@export var p_meter_drain := 60.0
## Velocidade mínima para encher (= velocidade de correr)
@export var p_meter_min_speed := 135.0

@export_group("Ajudas")
## Tempo para ainda pular depois de sair da beirada (6 frames)
@export var coyote_time := 0.1
## Tempo que o aperto do pulo fica "guardado" antes de tocar o chão
@export var jump_buffer_time := 0.1

@export_group("Rampas / Slide")
## Velocidade máxima deslizando
@export var slide_max_speed := 240.0
## Freada do slide no chão reto (3/frame)
@export var slide_friction := 180.0

@export_group("Efeitos")
## Cena da fumaça da derrapada
@export var skid_smoke_scene: PackedScene = preload("res://scenes/vfx/skid_smoke.tscn")
## Altura dos pés em relação à origem do Mario (onde nasce a fumaça)
@export var feet_offset := 15.0

# --- Estado ---
var power_form: PowerForm = PowerForm.SMALL
var small_sprite_frames: SpriteFrames
var hammer: Hammer = null

var is_invulnerable := false
var is_power_down := false
var is_attacking := false
var is_dead := false
var is_sliding := false

## Botão que precisa estar segurado para o pulo ir alto
var jump_hold_action := ACTION_JUMP

## Medidor P (0 a p_meter_max). Cheio = disparada.
var p_meter := 0.0
## Pulou em disparada: o medidor não esvazia no ar
var _sprint_jump := false

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0


func _ready() -> void:
	small_sprite_frames = animated_sprite.sprite_frames
	animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT
	powerup_sound.process_mode = Node.PROCESS_MODE_ALWAYS

	standing_shape.shape = standing_shape.shape.duplicate()
	standing_shape.position = Vector2(0, 7.5)
	(standing_shape.shape as RectangleShape2D).size = Vector2(12, 15)

	# Rampas
	floor_max_angle = deg_to_rad(70)  # aceita até a rampa muito íngreme
	floor_snap_length = 8.0
	floor_constant_speed = true
	floor_stop_on_slope = true

	var saved := GameManager.player_form as PowerForm
	if saved != PowerForm.SMALL:
		set_form(saved)

	state_machine.init(self)


func _physics_process(delta: float) -> void:
	_update_jump_timers(delta)
	_update_p_meter(delta)
	floor_snap_length = 16.0 if is_on_slope() else 8.0

	attack.handle_input()
	attack.save_frame()

	state_machine.process_physics(delta)

	attack.apply_override()

	_attempt_correction(delta, 2)

	if not is_on_floor() and state_machine.current_state.can_apply_gravity():
		_apply_gravity(delta)

	move_and_slide()

	_check_ceiling_blocks()


# ============================================================
#  Dano / morte
# ============================================================

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


## Pulinho ao pisar num inimigo. Segurando pulo vai alto, soltando vai baixo.
func bounce() -> void:
	var holding := Input.is_action_pressed(ACTION_JUMP) \
		or (InputMap.has_action(ACTION_SPIN) and Input.is_action_pressed(ACTION_SPIN))
	velocity.y = -(BOUNCE_HIGH if holding else BOUNCE_LOW)
	jump_hold_action = ACTION_JUMP
	klock_sound.play()
	state_machine.change_state(state_machine.air)


# ============================================================
#  Movimento (usado pelos estados)
# ============================================================

func get_input_x() -> float:
	return Input.get_axis(ACTION_LEFT, ACTION_RIGHT)


func is_sprinting() -> bool:
	return p_meter >= p_meter_max


## Velocidade máxima atual, considerando correr, medidor P e rampa
func get_target_speed() -> float:
	var running := Input.is_action_pressed(ACTION_RUN)
	if running and is_sprinting():
		return sprint_speed  # na disparada a rampa não muda nada

	var type := get_slope_type()
	if type == SlopeType.FLAT:
		return run_speed if running else walk_speed

	var table: Dictionary = RUN_SLOPE_SPEEDS if running else WALK_SLOPE_SPEEDS
	return table[type][1 if is_moving_up_slope() else 0]


func get_skid_decel() -> float:
	return skid_decel_run if Input.is_action_pressed(ACTION_RUN) else skid_decel


func ground_move(delta: float) -> void:
	var type := get_slope_type()

	# Rampa muito íngreme: escorrega sempre
	if type == SlopeType.VERY_STEEP:
		velocity.x = move_toward(velocity.x, get_slope_dir() * slide_max_speed,
			SLIDE_ACCELS[type] * delta)
		return

	var input := get_input_x()
	if input == 0.0:
		# Solto: freia (numa rampa íngreme, escorrega devagar)
		var stop_speed: float = STAND_SLOPE_SLIDE[type] * get_slope_dir()
		velocity.x = move_toward(velocity.x, stop_speed, ground_friction * delta)
	elif velocity.x != 0.0 and signf(velocity.x) != signf(input):
		velocity.x = move_toward(velocity.x, input, get_skid_decel() * delta)
	else:
		velocity.x = move_toward(velocity.x, input * get_target_speed(), ground_accel * delta)


func air_move(delta: float) -> void:
	var input := get_input_x()
	if input == 0.0:
		return  # no ar o embalo se mantém
	if velocity.x != 0.0 and signf(velocity.x) != signf(input):
		var decel := air_skid_decel_run if Input.is_action_pressed(ACTION_RUN) else air_skid_decel
		velocity.x = move_toward(velocity.x, input, decel * delta)
	else:
		velocity.x = move_toward(velocity.x, input * get_target_speed(), air_accel * delta)


func _update_p_meter(delta: float) -> void:
	if is_on_floor():
		_sprint_jump = false
		if Input.is_action_pressed(ACTION_RUN) and absf(velocity.x) >= p_meter_min_speed:
			p_meter = minf(p_meter + p_meter_fill * delta, p_meter_max)
		else:
			p_meter = maxf(p_meter - p_meter_drain * delta, 0.0)
	elif not (_sprint_jump and Input.is_action_pressed(ACTION_RUN)):
		_sprint_jump = false
		p_meter = maxf(p_meter - p_meter_drain * delta, 0.0)


func update_facing() -> void:
	if is_attacking:
		return
	var input := get_input_x()
	if input != 0.0:
		animated_sprite.flip_h = input < 0.0


## Toca uma animação se ela existir (com fallback opcional).
func play_anim(anim_name: String, fallback := "", speed := 1.0) -> void:
	if is_attacking:
		return
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	elif fallback != "" and frames.has_animation(fallback):
		animated_sprite.play(fallback)
	animated_sprite.speed_scale = speed


# ============================================================
#  Pulo
# ============================================================

func wants_jump() -> bool:
	return _jump_buffer_timer > 0.0


func can_jump() -> bool:
	return _coyote_timer > 0.0


func wants_spin_jump() -> bool:
	return InputMap.has_action(ACTION_SPIN) and Input.is_action_just_pressed(ACTION_SPIN)


## Quanto mais rápido, mais alto: -(base + incremento x degraus de 30 px/s)
func _calc_jump(base: float, incr: float) -> float:
	return -(base + incr * int(absf(velocity.x) / 30.0))


func jump() -> void:
	velocity.y = _calc_jump(jump_base, jump_incr)
	_sprint_jump = is_sprinting()
	_consume_jump()
	jump_hold_action = ACTION_JUMP
	jump_sound.play()
	state_machine.change_state(state_machine.air)


func spin_jump() -> void:
	velocity.y = _calc_jump(spin_jump_base, spin_jump_incr)
	_sprint_jump = false
	_consume_jump()
	jump_hold_action = ACTION_SPIN
	spin_jump_sound.play()
	state_machine.change_state(state_machine.spin_jump)


func _consume_jump() -> void:
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


func _update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed(ACTION_JUMP):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)


## Gravidade do SMW: mais leve enquanto o botão de pulo estiver segurado
## (subindo OU caindo). É isso que faz o pulo ser mais alto segurando.
func _apply_gravity(delta: float) -> void:
	var g := gravity_hold if Input.is_action_pressed(jump_hold_action) else gravity
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


# ============================================================
#  Agachar / rampas
# ============================================================

func set_ducking(on: bool) -> void:
	duck_shape.disabled = not on
	standing_shape.disabled = on


## Tem espaço para ficar em pé? (evita levantar dentro de um bloco)
func can_stand_up() -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = standing_shape.shape
	params.transform = standing_shape.global_transform.translated(Vector2(0, -1))
	params.collision_mask = collision_mask
	params.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(params, 1).is_empty()


## -1 = rampa desce para a esquerda, 1 = para a direita, 0 = chão reto
func get_slope_dir() -> float:
	if not is_on_floor():
		return 0.0
	var n := get_floor_normal()
	if absf(n.x) < 0.1:
		return 0.0
	return signf(n.x)


func is_on_slope() -> bool:
	return get_slope_type() != SlopeType.FLAT


## Classifica a rampa pelo ângulo (como as rampas do SMW)
func get_slope_type() -> SlopeType:
	if not is_on_floor():
		return SlopeType.FLAT
	var angle := rad_to_deg(get_floor_angle())
	if angle < 5.0:
		return SlopeType.FLAT
	if angle < 20.0:
		return SlopeType.GRADUAL     # ~14°
	if angle < 35.0:
		return SlopeType.NORMAL      # ~26°
	if angle < 54.0:
		return SlopeType.STEEP       # 45°
	return SlopeType.VERY_STEEP      # ~63°


## Está indo morro acima?
func is_moving_up_slope() -> bool:
	var slope := get_slope_dir()
	if slope == 0.0:
		return false
	var dir := get_input_x()
	if dir == 0.0:
		dir = signf(velocity.x)
	return dir != 0.0 and signf(dir) != slope


## Aceleração do slide na rampa atual
func get_slide_accel() -> float:
	return SLIDE_ACCELS[get_slope_type()]


## Solta uma nuvem de fumaça nos pés (derrapada / slide)
func spawn_skid_smoke() -> void:
	if skid_smoke_scene == null:
		return
	var smoke := skid_smoke_scene.instantiate() as Node2D
	# Posição definida ANTES de entrar na cena (o _ready da fumaça já usa ela)
	smoke.position = global_position + Vector2(0, feet_offset)
	get_tree().current_scene.add_child(smoke)


# ============================================================
#  Blocos e correção de canto
# ============================================================

func _check_ceiling_blocks() -> void:
	if not is_on_ceiling():
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider = col.get_collider()
		if collider is InteractableBlock and col.get_normal().y > 0.5:
			velocity.y = 10.0
			collider.hit_by_player(self)
			break


func _attempt_correction(delta: float, amount: int) -> void:
	if velocity.y < 0 and test_move(global_transform, Vector2(0, velocity.y * delta)):
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


# ============================================================
#  Atalhos (outros scripts continuam chamando o Player)
# ============================================================

func set_form(form: PowerForm) -> void: powers.set_form(form)
func power_down() -> void: powers.power_down()
func grow_animation() -> void: await powers.grow_animation()
func collect_mushroom() -> void: powers.collect_mushroom()
func collect_fire_flower() -> void: powers.collect_fire_flower()
func collect_hammer() -> void: powers.collect_hammer()
func can_collect_hammer() -> bool: return powers.can_collect_hammer()
func can_collect_fire_flower() -> bool: return powers.can_collect_fire_flower()

func try_throw_fireball() -> bool: return attack.try_throw_fireball()
func try_throw_hammer() -> void: attack.try_throw_hammer()
func can_use_hammer() -> bool: return attack.can_use_hammer()
func try_hammer_attack() -> bool: return attack.try_hammer_attack()
