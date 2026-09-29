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

func exit() -> void:
	flipping = false
	can_land = true
	flip_timer = 0.0
	land_timer = 0.0
	player.animated_sprite.speed_scale = 1.0
