## Original short UI tone. Fixed pool and dedicated bus; survives scene changes.
## Pool/bus pattern: godot-audio-systems skill; PCM API: Godot 4.4 AudioStreamWAV.
extends Node

const BUS := "ElementGuardians_UI"
const VOICES := 4
var enabled: bool = true
var pool: Array[AudioStreamPlayer] = []
var stream: AudioStreamWAV
var play_count: int = 0

func _ready() -> void:
	name = "PlayerUIAudio"
	if AudioServer.get_bus_index(BUS) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS)
		AudioServer.set_bus_send(AudioServer.get_bus_index(BUS), "Master")
	stream = _make_click()
	for index in range(VOICES):
		var voice := AudioStreamPlayer.new()
		voice.stream = stream
		voice.bus = BUS
		voice.volume_db = -14.0
		add_child(voice)
		pool.append(voice)
	set_enabled(enabled)

func set_enabled(value: bool) -> void:
	enabled = value
	var index := AudioServer.get_bus_index(BUS)
	if index >= 0:
		AudioServer.set_bus_mute(index, not value)
	if not value:
		for voice in pool:
			voice.stop()

func play_click() -> void:
	if not enabled:
		return
	for voice in pool:
		if not voice.playing:
			voice.play()
			play_count += 1
			return
	# Drop excess input sounds instead of allocating nodes or stacking loudness.

func _make_click() -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	sample.mix_rate = 22050
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	var frames := int(sample.mix_rate * 0.065)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for index in range(frames):
		var t := float(index) / sample.mix_rate
		var envelope := minf(t / 0.004, 1.0) * pow(1.0 - float(index) / frames, 2.0)
		var tone := sin(TAU * 660.0 * t) * 0.75 + sin(TAU * 990.0 * t) * 0.25
		bytes.encode_s16(index * 2, int(tone * envelope * 22000))
	sample.data = bytes
	return sample
