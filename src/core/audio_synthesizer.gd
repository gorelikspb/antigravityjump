class_name AudioSynthesizer
extends RefCounted
## Procedural SFX generator for 8-bit / retro indie feel without external sound assets.
## Produces AudioStreamWAV directly in memory for crisp low-latency playback.

enum Sound {
	FLIP,
	DENY,
	JUMP,
	LAND,
	DEATH,
	CHECKPOINT,
	GOAL
}

static func create_stream(sound_type: Sound) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var samples: PackedByteArray = PackedByteArray()
	
	match sound_type:
		Sound.FLIP:
			# Ascending pitch chirp / laser flip (0.09s)
			var duration := 0.09
			var total_samples := int(sample_rate * duration)
			samples.resize(total_samples)
			for i in total_samples:
				var t := float(i) / sample_rate
				var progress := float(i) / total_samples
				var freq := lerpf(320.0, 780.0, progress)
				var env := 1.0 - progress
				var val := sin(TAU * freq * t) * env
				samples[i] = clampi(int(val * 110.0 + 128.0), 0, 255)
				
		Sound.DENY:
			# Low double buzzy tone for denied flip (0.12s)
			var duration := 0.12
			var total_samples := int(sample_rate * duration)
			samples.resize(total_samples)
			for i in total_samples:
				var t := float(i) / sample_rate
				var progress := float(i) / total_samples
				var freq := 110.0
				var env := (1.0 - progress) * (1.0 if fmod(t, 0.06) < 0.035 else 0.1)
				# square-ish wave
				var val := (1.0 if sin(TAU * freq * t) > 0.0 else -1.0) * env
				samples[i] = clampi(int(val * 90.0 + 128.0), 0, 255)

		Sound.JUMP:
			# Quick retro upward blip (0.08s)
			var duration := 0.08
			var total_samples := int(sample_rate * duration)
			samples.resize(total_samples)
			for i in total_samples:
				var t := float(i) / sample_rate
				var progress := float(i) / total_samples
				var freq := lerpf(220.0, 520.0, progress * progress)
				var env := 1.0 - progress
				var val := (1.0 if sin(TAU * freq * t) > 0.0 else -1.0) * 0.7 * env
				samples[i] = clampi(int(val * 90.0 + 128.0), 0, 255)

		Sound.LAND:
			# Soft low impact thud (0.06s)
			var duration := 0.06
			var total_samples := int(sample_rate * duration)
			samples.resize(total_samples)
			for i in total_samples:
				var t := float(i) / sample_rate
				var progress := float(i) / total_samples
				var freq := lerpf(120.0, 50.0, progress)
				var env := (1.0 - progress) * (1.0 - progress)
				var val := sin(TAU * freq * t) * env
				samples[i] = clampi(int(val * 100.0 + 128.0), 0, 255)

		Sound.DEATH:
			# Noise burst + downward slide (0.28s)
			var duration := 0.28
			var total_samples := int(sample_rate * duration)
			samples.resize(total_samples)
			for i in total_samples:
				var t := float(i) / sample_rate
				var progress := float(i) / total_samples
				var freq := lerpf(400.0, 70.0, progress)
				var noise := randf_range(-0.5, 0.5)
				var env := (1.0 - progress) * (1.0 - progress)
				var tone := sin(TAU * freq * t) * 0.6
				var val := (tone + noise * 0.4) * env
				samples[i] = clampi(int(val * 115.0 + 128.0), 0, 255)

		Sound.CHECKPOINT:
			# Cheerful 2-tone chime (0.16s)
			var duration := 0.16
			var total_samples := int(sample_rate * duration)
			samples.resize(total_samples)
			for i in total_samples:
				var t := float(i) / sample_rate
				var freq := 587.33 if t < 0.08 else 880.0 # D5 -> A5
				var env := 1.0 - fmod(t, 0.08) / 0.08
				var val := sin(TAU * freq * t) * env * 0.8
				samples[i] = clampi(int(val * 100.0 + 128.0), 0, 255)

		Sound.GOAL:
			# Victorious 3-tone arpeggio (0.32s)
			var duration := 0.32
			var total_samples := int(sample_rate * duration)
			samples.resize(total_samples)
			var notes: Array[float] = [523.25, 659.25, 1046.5]
			for i in total_samples:
				var t := float(i) / sample_rate
				var note_idx := clampi(int(t / 0.1), 0, 2)
				var freq: float = notes[note_idx] # C5, E5, C6
				var env := 1.0 - (fmod(t, 0.1) / 0.1) * 0.7
				var val := (sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)) * env * 0.65
				samples[i] = clampi(int(val * 110.0 + 128.0), 0, 255)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = samples
	return stream
