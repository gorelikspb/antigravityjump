extends Node
## Central sound manager. Pre-generates procedural retro SFX buffers in memory.
## Registered as Autoload so any system can trigger audio without scene dependencies.

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 6


func _ready() -> void:
	# Pre-build sound cache
	for s in AudioSynthesizer.Sound.values():
		_streams[s] = AudioSynthesizer.create_stream(s)
		
	# Pool of players to handle overlapping sounds
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: AudioSynthesizer.Sound, pitch_scale: float = 1.0) -> void:
	if not _streams.has(sound):
		return
	var stream: AudioStreamWAV = _streams[sound]
	
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch_scale
			p.play()
			return
			
	# If all busy, steal the first one
	_players[0].stream = stream
	_players[0].pitch_scale = pitch_scale
	_players[0].play()
