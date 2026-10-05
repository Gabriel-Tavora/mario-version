extends Control

@onready var lives_label: Label = $Container/Lives/HBoxContainer/LifeCount
@onready var time_left_count: Label = $Container/Time/HBoxContainer/Label
@onready var score_count: Label = $Container/Score/ScoreText
@onready var coin_count: Label = $Container/Score/Coins/Label
@onready var life_count: Control = $Container/Lives
@onready var item_box_sprite: Sprite2D = $ItemBoxSprite

## Arraste no Inspector a imagem de cada item que aparece na caixa
@export var mushroom_texture: Texture2D
@export var fire_flower_texture: Texture2D
@export var hammer_texture: Texture2D

var _item_textures := {}
var _base_scale := Vector2.ONE


func _ready() -> void:
	_base_scale = item_box_sprite.scale

	_item_textures = {
		"mushroom": mushroom_texture,
		"fire_flower": fire_flower_texture,
		"hammer": hammer_texture,
	}

	GameManager.item_box_changed.connect(_on_item_box_changed)
	_show_item(GameManager.item_box, false) # estado inicial, sem "pulinho"

	update_hud()


func _process(_delta: float) -> void:
	update_hud()


func update_hud() -> void:
	coin_count.text = str(GameManager.coins)
	score_count.text = str(GameManager.score)
	lives_label.text = str(GameManager.lives)
	time_left_count.text = str(GameManager.time)

	if GameManager.lives < 1:
		life_count.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		life_count.modulate = Color.WHITE


func _on_item_box_changed(item: String) -> void:
	_show_item(item, true)


func _show_item(item: String, animate: bool) -> void:
	var texture: Texture2D = _item_textures.get(item)

	# Sem item (ou sem textura definida): caixa vazia
	if item == "" or texture == null:
		item_box_sprite.hide()
		return

	item_box_sprite.texture = texture
	item_box_sprite.show()

	# Pulinho ao trocar de item
	if animate:
		item_box_sprite.scale = _base_scale * 1.4
		var tween := create_tween()
		tween.tween_property(item_box_sprite, "scale", _base_scale, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_timer_timeout() -> void:
	if GameManager.time <= 0:
		return

	GameManager.time -= 1
