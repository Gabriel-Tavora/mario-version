extends Control

@onready var options = [
	$Box/MarginContainer/Vbox/Label,
	$Box/MarginContainer/Vbox/Label2,
	$Box/MarginContainer/Vbox/Label3
]
@onready var arrow: TextureRect = $Arrow

var selected_index := 0
var can_select := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _process(_delta: float) -> void:
	visible = GameManager.game_paused

	if not GameManager.game_paused:
		if Input.is_action_just_pressed("pause"):
			pause_game()
		return

	if Input.is_action_just_pressed("pause"):
		resume_game()
		return

	if not can_select:
		return

	if Input.is_action_just_pressed("ui_down"):
		selected_index += 1
		if selected_index >= options.size():
			selected_index = 0

	elif Input.is_action_just_pressed("ui_up"):
		selected_index -= 1
		if selected_index < 0:
			selected_index = options.size() - 1

	elif Input.is_action_just_pressed("ui_accept"):
		option_selected()

	if options[selected_index] != null:
		arrow.global_position.y = options[selected_index].global_position.y

	selected_index = clamp(selected_index, 0, options.size() - 1)

func pause_game() -> void:
	GameManager.game_paused = true
	get_tree().paused = true
	can_select = true
	selected_index = 0

func resume_game() -> void:
	GameManager.game_paused = false
	get_tree().paused = false
	can_select = true

func option_selected() -> void:
	if not can_select:
		return

	can_select = false

	await select_animation(options[selected_index])

	match selected_index:
		0:
			resume_game()
		1:
			restart_level()
		2:
			pass

	can_select = true

func restart_level() -> void:
	get_tree().paused = false
	GameManager.game_paused = false

	var current_scene := get_tree().current_scene
	var scene_path := current_scene.scene_file_path

	get_tree().change_scene_to_file(scene_path)

func select_animation(option: Control) -> void:
	for i in 5:
		option.modulate.a = 0
		await get_tree().create_timer(0.05).timeout
		option.modulate.a = 1
		await get_tree().create_timer(0.05).timeout
