extends Node
# Original synthesized interface cues, not recordings of real weapons.
const RATE := 22050
var voices: Dictionary = {}

func _ready() -> void:
	build_cue("fire", 0.09, 180.0, 65.0, 0.22)
	build_cue("hit", 0.12, 620.0, 380.0, 0.14)
	build_cue("reload", 0.17, 280.0, 490.0, 0.12)
	build_cue("damage", 0.19, 150.0, 95.0, 0.19)
	build_cue("objective", 0.30, 440.0, 880.0, 0.12)
	build_cue("failure", 0.35, 320.0, 120.0, 0.12)

func build_cue(key: String, duration: float, start_hz: float, end_hz: float, amplitude: float) -> void:
	var frames := int(duration * RATE)
	var samples := PackedByteArray()
	samples.resize(frames * 2)
	var phase := 0.0
	for i in range(frames):
		var t := float(i) / float(frames)
		var envelope := minf(1.0, t * 35.0) * (1.0 - t) * (1.0 - t)
		phase += TAU * lerpf(start_hz, end_hz, t) / RATE
		var sample := sin(phase) * envelope * amplitude
		samples.encode_s16(i * 2, roundi(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = samples
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	add_child(voice)
	voices[key] = voice

func cue(key: String) -> void:
	var voice := voices.get(key) as AudioStreamPlayer
	if is_instance_valid(voice) and GameSettings.effects_volume > 0.0:
		voice.volume_db = linear_to_db(GameSettings.effects_volume)
		voice.play()
