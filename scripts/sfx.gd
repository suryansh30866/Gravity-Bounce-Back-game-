extends Node
## Small shared SFX pool. Every clip is loaded once when the project starts.

const CLIP_PATHS := {
	"ui_click": "res://assets/audio/sci-fi_sounds/Audio/laserSmall_000.ogg",
	"ui_hover": "res://assets/audio/sci-fi_sounds/Audio/computerNoise_000.ogg",
	"jump": "res://assets/audio/sci-fi_sounds/Audio/thrusterFire_000.ogg",
	"boost": "res://assets/audio/sci-fi_sounds/Audio/thrusterFire_002.ogg",
	"pickup": "res://assets/audio/sci-fi_sounds/Audio/laserRetro_000.ogg",
	"repair": "res://assets/audio/sci-fi_sounds/Audio/impactMetal_000.ogg",
	"alien_approach": "res://assets/audio/sci-fi_sounds/Audio/slime_000.ogg",
	"knockback": "res://assets/audio/sci-fi_sounds/Audio/explosionCrunch_000.ogg",
	"ship_boot": "res://assets/audio/sci-fi_sounds/Audio/computerNoise_002.ogg",
	"launch": "res://assets/audio/sci-fi_sounds/Audio/spaceEngineLarge_000.ogg",
	"engine": "res://assets/audio/sci-fi_sounds/Audio/thrusterFire_001.ogg",
	"ambient": "res://assets/audio/sci-fi_sounds/Audio/spaceEngineLow_000.ogg",
}
const SHIP_TRAVEL_PATH := "res://assets/audio/sci-fi_sounds/Spaceship start and travelling sound.mp3"

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _last_event_time: Dictionary = {}
var _ambient_player: AudioStreamPlayer
var _ship_travel_player: AudioStreamPlayer

func _ready() -> void:
	for event in CLIP_PATHS:
		_streams[event] = load(CLIP_PATHS[event])
	for index in 10:
		var player := AudioStreamPlayer.new()
		player.name = "SFX %02d" % index
		add_child(player)
		_players.append(player)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "Lunar ambient"
	var ambient_stream := _streams["ambient"] as AudioStreamOggVorbis
	ambient_stream.loop = true
	_ambient_player.stream = ambient_stream
	_ambient_player.volume_db = -24.0
	add_child(_ambient_player)
	_ship_travel_player = AudioStreamPlayer.new()
	_ship_travel_player.name = "Spaceship start and travel"
	var ship_stream := load(SHIP_TRAVEL_PATH) as AudioStreamMP3
	ship_stream.loop = true
	_ship_travel_player.stream = ship_stream
	_ship_travel_player.volume_db = -7.0
	add_child(_ship_travel_player)

func play_sfx(event: String, volume_db: float = -8.0) -> void:
	if not _streams.has(event):
		return
	var player: AudioStreamPlayer
	for candidate in _players:
		if not candidate.playing:
			player = candidate
			break
	if player == null:
		player = _players[0]
	player.stream = _streams[event] as AudioStream
	player.volume_db = volume_db
	player.play()

func play_once_per_interval(event: String, interval: float, volume_db: float = -8.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_event_time.get(event, -1000.0)) < interval:
		return
	_last_event_time[event] = now
	play_sfx(event, volume_db)

func start_ambient() -> void:
	if not _ambient_player.playing:
		_ambient_player.play()

func stop_ambient() -> void:
	_ambient_player.stop()

func start_ship_travel() -> void:
	if not _ship_travel_player.playing:
		_ship_travel_player.play()

func stop_ship_travel() -> void:
	_ship_travel_player.stop()
