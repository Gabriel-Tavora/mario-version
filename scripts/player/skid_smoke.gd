extends AnimatedSprite2D
## Nuvem de fumaça da derrapada.
## Os próprios frames já mostram a fumaça se desfazendo,
## então só toca a animação uma vez e se apaga no fim.

## Velocidade da animação (os frames estão a 5 FPS; 3x ≈ 0,33 s no total)
@export var anim_speed := 3.0
## Sobe um pouquinho enquanto some
@export var rise := 4.0


func _ready() -> void:
	var anim := &"skid"
	if not sprite_frames.has_animation(anim):
		anim = sprite_frames.get_animation_names()[0]

	# Garante que não fica em loop (senão nunca termina)
	sprite_frames.set_animation_loop(anim, false)

	animation_finished.connect(queue_free)
	speed_scale = anim_speed
	play(anim)

	var tween := create_tween()
	tween.tween_property(self, "position:y", -rise, _duration(anim)).as_relative()


func _duration(anim: StringName) -> float:
	var fps := sprite_frames.get_animation_speed(anim) * speed_scale
	if fps <= 0.0:
		return 0.3
	var total := 0.0
	for i in sprite_frames.get_frame_count(anim):
		total += sprite_frames.get_frame_duration(anim, i)
	return total / fps
