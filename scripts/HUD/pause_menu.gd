extends Control

# Atenção: o nó se chama "VBox" (com B maiúsculo). O caminho antigo usava
# "Vbox", então as opções ficavam null e a seta nunca se movia.
@onready var options: Array[Control] = [
	$Box/MarginContainer/VBox/Label,
	$Box/MarginContainer/VBox/Label2,
	$Box/MarginContainer/VBox/Label3,
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
		selected_index = (selected_index + 1) % options.size()
	elif Input.is_action_just_pressed("ui_up"):
		selected_index = (selected_index - 1 + options.size()) % options.size()
	elif Input.is_action_just_pressed("ui_accept"):
		option_selected()

	_update_arrow()


## Centraliza a seta na altura da opção selecionada
func _update_arrow() -> void:
	var option := options[selected_index]
	arrow.global_position.y = option.global_position.y + (option.size.y - arrow.size.y) / 2.0


func pause_game() -> void:
	GameManager.game_paused = true
	get_tree().paused = true
	can_select = true
	selected_index = 0
	_update_arrow()


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
			# Reinicia a fase sem gastar vida (a lógica está no GameManager)
			GameManager.restart_level()
		2:
			pass # opção 3: coloque aqui o que ela faz (ex.: voltar ao menu)

	can_select = true


func select_animation(option: Control) -> void:
	for i in 5:
		option.modulate.a = 0
		await get_tree().create_timer(0.05).timeout
		option.modulate.a = 1
		await get_tree().create_timer(0.05).timeout
