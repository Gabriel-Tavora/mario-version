extends Enemy

const move_speed := 75

var can_play := true
var can_move := true

@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D

@export var starting_direction := 1

func _ready() -> void:
	super._ready()

	dir = starting_direction
	sprite.scale.x = abs(sprite.scale.x) * (-1 if dir < 0 else 1)

	visible_on_screen_enabler_2d.screen_exited.connect(_on_screen_exited)

func _physics_process(delta: float) -> void:
	if not can_move:
		# Caindo depois de ser pisado
		velocity.x = 0
		velocity.y += 900 * delta
		move_and_slide()
		if global_position.y > 1000:
			queue_free()
		return

	global_position.x += (-move_speed * dir) * delta

func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	if can_play:
		SoundManager.play_sfx(SoundManager.bullet, self)
		can_play = false

func _on_screen_exited() -> void:
	# Saiu da tela caindo → some
	if is_dead:
		queue_free()

# Sobrescreve o die() do Enemy: só cai, sem giro nem puff
func die() -> void:
	if is_dead:
		return

	is_dead = true
	can_move = false

	stomp_area.set_deferred("monitoring", false)
	hurt_area.set_deferred("monitoring", false)
	physics_shape.set_deferred("disabled", true)  # atravessa o chão

	velocity = Vector2.ZERO
