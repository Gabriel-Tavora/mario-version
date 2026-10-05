class_name KoopaShell
extends CharacterBody2D

const SHELL_SPEED := 120.0
const GRAVITY := 900.0
const WAKE_TIME := 25.0 # segundos parado até o Koopa sair do casco

var direction := 0
var shell_moving := false

# Preenchido pelo Koopa que virou casco. Vazio = casco colocado direto na fase
# (nesse caso ele nunca volta a ser Koopa).
var koopa_scene_path := ""
var _idle_time := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stomp_area: Area2D = $StompArea
@onready var hit_area: Area2D = $HitArea


func _ready() -> void:
	sprite.play("idle")

	stomp_area.body_entered.connect(_on_stomp_area_body_entered)
	hit_area.body_entered.connect(_on_hit_area_body_entered)

	hit_area.monitoring = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if shell_moving:
		velocity.x = SHELL_SPEED * direction
		sprite.play("spinning")
		_idle_time = 0.0
	else:
		velocity.x = 0
		sprite.play("idle")
		_check_wake_up(delta)

	move_and_slide()

	if is_on_wall() and shell_moving:
		direction *= -1
		sprite.flip_h = direction > 0


## Parado por WAKE_TIME segundos: o Koopa sai do casco e volta a andar.
func _check_wake_up(delta: float) -> void:
	if koopa_scene_path == "":
		return

	_idle_time += delta
	if _idle_time >= WAKE_TIME:
		wake_up()


func wake_up() -> void:
	# load() em vez de preload() para não criar dependência circular
	# com o koopa.tscn (que já carrega este casco).
	var koopa_scene := load(koopa_scene_path) as PackedScene
	if koopa_scene == null:
		return

	var koopa = koopa_scene.instantiate()
	get_parent().add_child(koopa)
	koopa.global_position = global_position + Vector2(0, -8)
	queue_free()


func _on_stomp_area_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	if body.velocity.y < 0:
		return

	if body.global_position.y > global_position.y:
		return

	body.bounce()

	if shell_moving:
		stop_shell()
	else:
		kick_shell(body)


func kick_shell(player: Player) -> void:
	if player.global_position.x < global_position.x:
		direction = 1
	else:
		direction = -1

	shell_moving = true
	velocity.x = SHELL_SPEED * direction
	_idle_time = 0.0

	hit_area.set_deferred("monitoring", true)

	sprite.play("spinning")
	sprite.flip_h = direction > 0

func stop_shell() -> void:
	shell_moving = false
	direction = 0
	velocity.x = 0
	_idle_time = 0.0

	hit_area.set_deferred("monitoring", false)

	sprite.play("idle")


## Bola de fogo estoura no casco sem matar nada.
func take_fire_hit() -> bool:
	return false


func _on_hit_area_body_entered(body: Node2D) -> void:
	if body is Player:
		if shell_moving:
			body.die()
		else:
			kick_shell(body)
		return

	if shell_moving and body is Enemy:
		body.die()
