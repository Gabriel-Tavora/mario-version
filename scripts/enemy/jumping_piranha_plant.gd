extends Enemy

const jump_force := -350

@export var shoots_fireball := false
@export var fireball_scene: PackedScene  # arraste a cena da bola de fogo aqui
@export var autumn := false

@onready var starting_position := global_position
@onready var player_detect_area: Area2D = $PlayerDetect/Area
@onready var autumn_sprite: AnimatedSprite2D = $AutumnSprite
@onready var timer: Timer = $Timer

var jump_queued := false
var can_jump := true
var player_block := false

func _ready() -> void:
	# Não chama super._ready(): os nós desta cena têm outros nomes
	sprite = $Sprite
	hurt_area = $Hitbox
	hurt_area.body_entered.connect(_on_hurt_area_entered)  # encostou = Mario morre

	timer.one_shot = true
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

	spawn()

func spawn() -> void:
	if autumn:
		sprite.hide()
		autumn_sprite.show()
		sprite = autumn_sprite
	sprite.play()

	global_position.y += 16
	await get_tree().create_timer(4, false).timeout
	jump()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	velocity.y += 8
	velocity.y = clamp(velocity.y, -99999, 25)
	global_position.y = clamp(global_position.y, -999999, starting_position.y + 16)

	# Mario perto do cano → não pula
	player_block = player_detect_area.get_overlapping_bodies().any(
		func(body: Node2D): return body is Player
	)

	move_and_slide()

func jump() -> void:
	if is_dead:
		return
	if player_block:
		jump_queued = true
		timer.start()
		return
	if not can_jump:
		timer.start()
		return

	can_jump = false
	jump_queued = false
	velocity.y = jump_force

	await get_tree().create_timer(0.5, false).timeout
	if is_dead:
		return
	if shoots_fireball:
		fireball()

	await get_tree().create_timer(5, false).timeout
	if is_dead:
		return
	can_jump = true
	timer.start()

func fireball() -> void:
	if fireball_scene == null:
		return
	for i in [-1, 1]:
		var node = fireball_scene.instantiate()
		node.global_position = global_position
		node.direction = i
		add_sibling(node)

func _on_timer_timeout() -> void:
	if player_block:
		timer.start(2)
	else:
		jump()

# Planta não cai: some com o puff (fogo/martelo chamam die())
func die() -> void:
	if is_dead:
		return
	is_dead = true
	timer.stop()
	hurt_area.set_deferred("monitoring", false)

	var puff = PUFF_SCENE.instantiate()
	puff.global_position = global_position + Vector2(0, -4)
	get_tree().current_scene.add_child(puff)
	puff.play_puff()

	queue_free()
