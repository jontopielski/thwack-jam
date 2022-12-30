extends Node

export(bool) var is_muted = false

func stop_all_songs():
	for song in $Music.get_children():
		if song.playing:
			song.stop()

func play_song(song_name):
	if is_muted:
		return
	for song in $Music.get_children():
		if song.name == song_name and !song.playing:
			stop_all_songs()
			song.play()

func play_sfx(sound_name):
	if is_muted:
		return
	for sound in $Sounds.get_children():
		if sound.name == sound_name:
			sound.play()
