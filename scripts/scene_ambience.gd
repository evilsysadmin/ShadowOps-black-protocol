extends Node3D
# Original periodic synthesis, with no recordings or downloaded assets.
const RATE := 11025
const SECONDS := 4
const FRAMES := RATE * SECONDS
var profile := "safehouse"
var voice: AudioStreamPlayer3D
var applied_volume := -1.0

static func profile_for(operation: String) -> String:
	match operation:
		"unexpected_guest":
			return "hotel"
		"silent_archive":
			return "archive"
		"night_relay":
			return "relay"
	return "safehouse"

# Integer frequencies and periodic modulation keep the loop boundary continuous.
static func make_loop(kind: String) -> AudioStreamWAV:
	var fundamental := 50.0
	var overtone := 100.0
	var texture := 151.0
	match kind:
		"hotel":
			fundamental = 42.0
			overtone = 84.0
			texture = 127.0
		"archive":
			fundamental = 58.0
			overtone = 116.0
			texture = 233.0
		"relay":
			fundamental = 60.0
			overtone = 180.0
			texture = 301.0
	var samples := PackedByteArray()
	samples.resize(FRAMES * 2)
	for i in range(FRAMES):
		var time := float(i) / RATE
		var phase := TAU * time
		var swell := 0.7 + 0.3 * sin(phase * 0.25)
		var sample := sin(phase * fundamental) * 0.08
		sample += sin(phase * overtone) * 0.035 * swell
		sample += sin(phase * texture) * 0.018 * (0.6 + 0.4 * cos(phase * 0.5))
		samples.encode_s16(i * 2, roundi(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = samples
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = FRAMES
	return stream

func _ready() -> void:
	voice = AudioStreamPlayer3D.new()
	voice.stream = make_loop(profile)
	voice.unit_size = 3.0
	voice.max_distance = 24.0
	add_child(voice)
	voice.volume_db = linear_to_db(maxf(GameSettings.ambient_volume, 0.0001))
	voice.play()
	refresh_volume()

func _process(_delta: float) -> void:
	refresh_volume()

func refresh_volume() -> void:
	var volume := GameSettings.ambient_volume
	if is_equal_approx(volume, applied_volume):
		return
	applied_volume = volume
	voice.volume_db = linear_to_db(maxf(volume, 0.0001))
	# A zero setting must be silent, not merely very quiet.
	voice.stream_paused = volume <= 0.0
