class_name Fireball
extends CharacterBody2D
## Bola de fogo do Mario Fire.
##
## Cena PlayerFireball:
## PlayerFireball (CharacterBody2D)      <- este script
## ├── AnimatedSprite2D
## ├── CollisionShape2D                  (CircleShape2D ~ raio 4)
## ├── VisibleOnScreenNotifier2D
## ├── interactionArea (Area2D)          (mask = inimigos)
## │   └── CollisionShape2D              (precisa de uma shape!)
## └── FlameEmber (partículas)

const GRAVITY := 900.0          # equivale aos "+15 por frame" a 60 FPS
const BOUNCE_SPEED := -175.0
const MAX_FALL_SPEED := 200.0
const SPIN_DEG_PER_SEC := 1800.0 # equivale a 30° por frame a 60 FPS
const LIFETIME := 5.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ember: Node = get_node_or_null("FlameEmber")
@onready var interaction_area: Area2D = $interactionArea
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

# Defina ANTES de add_child(): fireball.player = self; fireball.direction = 1 ou -1
var player: Player = null
var direction := 1

var speed := 200.0
var _life := LIFETIME
var _done := false


func _ready() -> void:
	add_to_group("fireball") # usado para limitar a 2 na tela

	if ember:
		ember.show()
		ember.emitting = true
		if ember.has_method("restart"):
			ember.restart()

	if is_instance_valid(player):
		# A bola nasce colada no Mario: sem isto ela empurra o Mario
		# e vira "parede", estourando no primeiro frame.
		add_collision_exception_with(player)
		player.add_collision_exception_with(self)
		speed += abs(player.velocity.x / 2.0)

	sprite.scale.x = -direction
	velocity.y = speed

	interaction_area.area_entered.connect(_on_target_entered)
	interaction_area.body_entered.connect(_on_target_entered)
	screen_notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	if _done:
		return

	sprite.rotation_degrees += SPIN_DEG_PER_SEC * direction * delta

	velocity.x = speed * direction

	if is_on_floor():
		velocity.y = BOUNCE_SPEED - (get_floor_normal().x * 16.0)

	velocity.y += GRAVITY * delta
	velocity.y = clamp(velocity.y, -speed, MAX_FALL_SPEED)

	if is_on_wall():
		hit_solid()
		return

	move_and_slide()

	_life -= delta
	if _life <= 0.0:
		hit_solid()


func hit_solid() -> void:
	if _done:
		return
	_done = true

	SoundManager.play_bump()
	# Opcional: invocar uma partícula de "puff" aqui, se você tiver uma:
	# ParticleManager.summon_particle(SUA_PARTICULA, global_position)
	_finish()


## Esconde a bola, para a física e deixa as partículas do FlameEmber
## terminarem antes de remover (queue_free direto cortaria o rastro).
func _finish() -> void:
	_done = true
	sprite.hide()
	set_physics_process(false)

	var shape := get_node_or_null("CollisionShape2D")
	if shape:
		shape.set_deferred("disabled", true)
	interaction_area.set_deferred("monitoring", false)

	var wait := 0.0
	if ember:
		ember.emitting = false
		wait = ember.lifetime

	if wait > 0.0:
		await get_tree().create_timer(wait).timeout
	queue_free()


func _on_target_entered(target: Node) -> void:
	if _done or target == player:
		return

	# O Area2D do inimigo pode ser filho do corpo principal
	var enemy: Node = target
	if not enemy.has_method("take_fire_hit"):
		if target.owner and target.owner.has_method("take_fire_hit"):
			enemy = target.owner
		elif target.get_parent() and target.get_parent().has_method("take_fire_hit"):
			enemy = target.get_parent()
		else:
			return

	# Inimigo já morrendo: a bola passa direto
	if enemy.get("is_dead") == true:
		return

	# take_fire_hit() retorna true se matou, false se o alvo é imune
	var killed = enemy.take_fire_hit()
	if killed == false:
		hit_solid()
		return

	_finish()
