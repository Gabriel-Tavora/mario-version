extends PlayerState
## Flip parado no ar, despenca reto, quebra blocos embaixo e pousa com impacto.

@export var flip_time := 0.25
@export var pound_speed := 275.0
@export var land_time := 0.5
## Posição do efeito de impacto em relação ao Mario
@export var impact_offset := Vector2.ZERO

var _flipping := true
var _landed := false
var _timer := 0.0


func enter() -> void:
	_flipping = true
	_landed = false
	_timer = flip_time

	player.velocity = Vector2.ZERO
	player.play_anim("Flip", "GroundPoundAir")


func exit() -> void:
	player.animated_sprite.speed_scale = 1.0


func can_apply_gravity() -> bool:
	return false  # este estado controla a queda


func physics_update(delta: float) -> void:
	# 1) Flip parado no ar
	if _flipping:
		player.velocity = Vector2.ZERO
		_timer -= delta
		if _timer <= 0.0:
			_flipping = false
			player.velocity = Vector2(0.0, pound_speed)
			player.play_anim("GroundPoundAir", "Fall")
		return

	# 2) Já pousou: espera e levanta
	if _landed:
		player.velocity = Vector2.ZERO
		_timer -= delta
		if _timer <= 0.0:
			land()
		return

	# 3) Caindo: acerta blocos; se só havia bricks e quebraram, continua caindo
	if _pound_blocks_below() or not player.is_on_floor():
		player.velocity = Vector2(0.0, pound_speed)
		player.play_anim("GroundPoundAir", "Fall")
		return

	# 4) Bateu no chão
	_landed = true
	_timer = land_time
	player.velocity = Vector2.ZERO
	player.play_anim("GroundPoundLand", "Crouch")
	ParticleManager.summon_particle(
		ParticleManager.GROUND_POUND_IMPACT,
		player.global_position + impact_offset
	)


## Ativa os blocos (question, spin, brick...) embaixo do Mario.
## Retorna true quando o Mario deve CONTINUAR caindo: só havia
## bricks e todos quebraram (não sobrou nada sólido embaixo).
func _pound_blocks_below() -> bool:
	var hit_any := false
	var found_solid := false

	for i in player.get_slide_collision_count():
		var col := player.get_slide_collision(i)

		# Só colisões vindas de baixo
		if col.get_normal().y > -0.5:
			continue

		var collider = col.get_collider()

		if collider is InteractableBlock:
			# Brick já quebrado: ignora
			if collider is BrickBlock and not collider.can_break:
				continue

			collider.hit_by_player(player, true)  # true = golpe vindo de cima
			hit_any = true

			# Acabou de quebrar: não conta como chão
			if collider is BrickBlock and not collider.can_break:
				continue

		found_solid = true

	return hit_any and not found_solid
