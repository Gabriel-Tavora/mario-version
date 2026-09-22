extends Node

var coin_sound: AudioStream = preload("res://audio/smw/player/coin.wav")
var shatter_sound: AudioStream = preload("res://audio/smw/world/shatter.wav")
var bump_sound: AudioStream = preload("res://audio/smw/player/bump.wav")


func play_coin() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = coin_sound
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func play_shatter() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = shatter_sound
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func play_bump() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = bump_sound
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
