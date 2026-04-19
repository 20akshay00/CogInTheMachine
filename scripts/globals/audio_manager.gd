extends AudioStreamPlayer

var part_equip_sfx = preload("res://assets/audio/partattach4.mp3")
var part_unequip_sfx = preload("res://assets/audio/partdetach2.mp3")

func _play_music(music: AudioStream, volume = -7):
	if stream == music:
		return

	stream = music
	volume_db = volume
	play()

func play_music_level():
	pass

func play_effect(aud_stream: AudioStream, volume = 0.0, bus="Misc"):
	var fx_player = AudioStreamPlayer.new()
	fx_player.stream = aud_stream
	fx_player.name = "FX_PLAYER"
	fx_player.volume_db = volume
	fx_player.bus = bus
	add_child(fx_player)
	fx_player.play()
	fx_player.finished.connect(fx_player.queue_free)

	return fx_player
	
func play_spatial_effect(aud_stream: AudioStream, position=Vector2.ZERO, volume = 0.0, bus="Misc"):
	var fx_player = AudioStreamPlayer2D.new()
	fx_player.global_position = position
	fx_player.stream = aud_stream
	fx_player.name = "FX_PLAYER"
	fx_player.volume_db = volume
	add_child(fx_player)
	fx_player.play()
	fx_player.finished.connect(fx_player.queue_free)

	return fx_player
