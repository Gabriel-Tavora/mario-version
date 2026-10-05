extends State

const FLIP_TIME := 0.25
const GROUND_POUND_SPEED := 275.0
const LAND_TIME := 0.5

var flipping := true
var can_land := true
var flip_timer := 0.0
var land_timer := 0.0

func enter() -> void:
	flipping = true
	can_land = true
	flip_timer = FLIP_TIME
	land_timer = LAND_TIME

	player.velocity = Vector2.ZERO
	player.animated_sprite.speed_scale = 1.0
	player.animated_sprite.play("Flip")

func physics_update(delta: float) -> void:
	if flipping:
		player.velocity = Vector2.ZERO
		flip_timer -= delta

		if flip_timer <= 0:
			flipping = false
			player.velocity.y = GROUND_POUND_SPEED
			player.animated_sprite.play("GroundPoundAir")

		return

	# Acerta os blocos que o Mario bateu no frame anterior.
	# Se só quebrou brick(s), continua caindo em vez de pousar.
	if _pound_blocks_below():
		player.velocity.x = 0
		player.velocity.y = GROUND_POUND_SPEED
		return

	if not player.is_on_floor():
		player.velocity.x = 0
		player.velocity.y = GROUND_POUND_SPEED

		if player.animated_sprite.animation != "GroundPoundAir":
			player.animated_sprite.play("GroundPoundAir")

		return

	if can_land:
		can_land = false
		land_timer = LAND_TIME
		player.velocity = Vector2.ZERO
		player.animated_sprite.play("GroundPoundLand")
		ParticleManager.summon_particle(
			ParticleManager.GROUND_POUND_IMPACT,
			player.global_position
		)

	land_timer -= delta

	if land_timer <= 0:
		state_machine.change_state(state_machine.idle)

## Ativa os blocos (question, spin, brick...) embaixo do Mario.
## Retorna true quando o Mario deve CONTINUAR caindo: só havia
## bricks e todos quebraram (não sobrou nada sólido embaixo).
func _pound_blocks_below() -> bool:
	if not can_land:
		return false # já pousou, não acerta de novo

	var hit_any := false
	var found_solid := false

	for i in player.get_slide_collision_count():
		var col = player.get_slide_collision(i)

		# Só colisões vindas de baixo
		if col.get_normal().y > -0.5:
			continue

		var collider = col.get_collider()

		if collider is InteractableBlock:
			# Brick já quebrado: ignora
			if collider is BrickBlock and not collider.can_break:
				continue

			collider.hit_by_player(player, true)   # true = golpe vindo de cima
			hit_any = true

			# Se acabou de quebrar, não conta como chão
			if collider is BrickBlock and not collider.can_break:
				continue

		found_solid = true

	return hit_any and not found_solid

func exit() -> void:
	flipping = false
	can_land = true
	flip_timer = 0.0
	land_timer = 0.0
	player.animated_sprite.speed_scale = 1.0
