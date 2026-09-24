class_name KoopaShell
extends CharacterBody2D

const SHELL_SPEED := 120.0
const GRAVITY := 900.0

var direction := 0
var shell_moving := false

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
	else:
		velocity.x = 0
		sprite.play("idle")

	move_and_slide()

	if is_on_wall() and shell_moving:
		direction *= -1
		sprite.flip_h = direction > 0


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

	hit_area.set_deferred("monitoring", true)

	sprite.play("spinning")
	sprite.flip_h = direction > 0
	
func stop_shell() -> void:
	shell_moving = false
	direction = 0
	velocity.x = 0

	hit_area.set_deferred("monitoring", false)

	sprite.play("idle")


func _on_hit_area_body_entered(body: Node2D) -> void:
	if body is Player:
		if shell_moving:
			body.die()
		else:
			kick_shell(body)
		return

	if shell_moving and body is Enemy:
		body.die()
