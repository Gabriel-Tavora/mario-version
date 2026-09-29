extends Node2D

@onready var particles: GPUParticles2D = $Flash

func _ready() -> void:
	var material := particles.material as CanvasItemMaterial

	if material == null:
		material = CanvasItemMaterial.new()
		particles.material = material

	material.particles_animation = true
	material.particles_anim_h_frames = 3
	material.particles_anim_v_frames = 1

	var process_material := particles.process_material as ParticleProcessMaterial

	if process_material:
		process_material.gravity = Vector3.ZERO
		process_material.initial_velocity_min = 0.0
		process_material.initial_velocity_max = 0.0
		process_material.anim_offset_min = randf()
		process_material.anim_offset_max = process_material.anim_offset_min

	particles.emitting = true

	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
