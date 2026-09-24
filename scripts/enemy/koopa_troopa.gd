class_name Koopa
extends CharacterBody2D

const SPEED := 40.0
const GRAVITY := 900.0
const SHELL_SCENE = preload("res://scenes/enamies/koopa_shell.tscn")

var direction := -1

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stomp_area: Area2D = $StompArea
@onready var hurt_area: Area2D = $HurtArea

func _ready() -> void:
	sprite.play("walk")
	stomp_area.body_entered.connect(_on_stomp_area_entered)
	hurt_area.body_entered.connect(_on_hurt_area_entered)

func _physics_process(delta: float) -> void:
	if not visible_on_screen_notifier_2d.is_on_screen():
		return

	sprite.flip_h = direction > 0

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.x = direction * SPEED

	move_and_slide()

	if is_on_wall():
		direction *= -1

func _on_stomp_area_entered(body: Node2D) -> void:
	if body is Player:
		if body.velocity.y >= 0:
			body.bounce()
			enter_shell()

func _on_hurt_area_entered(body: Node2D) -> void:
	if body is Player:
		body.die()

func enter_shell() -> void:
	var shell = SHELL_SCENE.instantiate()
	get_parent().add_child(shell)
	shell.global_position = global_position
	shell.velocity = Vector2.ZERO
	shell.direction = 0
	shell.shell_moving = false
	queue_free()
