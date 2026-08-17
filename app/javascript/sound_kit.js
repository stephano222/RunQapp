// タイピングの効果音。練習モードと写経モードの両方から使う。

// ペンタトニック音階。どの音を組み合わせても濁らないので、
// 連打しても不快にならず気持ちよく響く。
const PENTATONIC = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51]

const NOTE_INDEX = { C: 0, "C#": 1, D: 2, "D#": 3, E: 4, F: 5, "F#": 6, G: 7, "G#": 8, A: 9, "A#": 10, B: 11 }

// "C4" のような音名を周波数に変換する(A4 = 440Hz を基準にした平均律)
function noteToFrequency(note) {
  const match = /^([A-G]#?)(\d)$/.exec(note)
  if (!match) return 440
  const midi = (Number(match[2]) + 1) * 12 + NOTE_INDEX[match[1]]
  return 440 * Math.pow(2, (midi - 69) / 12)
}

// 収録するのは著作権の保護期間が終了した楽曲のみ。
// 1打ごとに次の音へ進み、最後まで行くと先頭に戻る。
const MELODIES = {
  default: null,
  piano: null,
  fur_elise: {
    label: "エリーゼのために",
    notes: ["E5", "D#5", "E5", "D#5", "E5", "B4", "D5", "C5", "A4",
            "C4", "E4", "A4", "B4", "E4", "G#4", "B4", "C5"]
  },
  ode_to_joy: {
    label: "歓喜の歌",
    notes: ["E4", "E4", "F4", "G4", "G4", "F4", "E4", "D4",
            "C4", "C4", "D4", "E4", "E4", "D4", "D4"]
  },
  sakura: {
    label: "さくらさくら",
    notes: ["A4", "A4", "B4", "A4", "A4", "B4", "A4", "G4", "E4",
            "D4", "E4", "G4", "E4", "D4"]
  },
  canon: {
    label: "カノン",
    notes: ["F#5", "E5", "D5", "C#5", "B4", "A4", "B4", "C#5",
            "D5", "C#5", "B4", "A4", "G4", "F#4", "G4", "E4"]
  },
  turkish_march: {
    label: "トルコ行進曲",
    notes: ["B4", "A4", "G#4", "A4", "C5", "D5", "C5", "B4",
            "C5", "E5", "F5", "E5", "D#5", "E5", "B5", "A5"]
  }
}

const SOUND_THEMES = [
  { key: "default", label: "デフォルト" },
  { key: "piano", label: "電子ピアノ" },
  { key: "fur_elise", label: "エリーゼのために" },
  { key: "ode_to_joy", label: "歓喜の歌" },
  { key: "sakura", label: "さくらさくら" },
  { key: "canon", label: "カノン" },
  { key: "turkish_march", label: "トルコ行進曲" }
]

// 電子ピアノモード用。白鍵を低い方から順に上がっていく。
const PIANO_SCALE = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5"]

class SoundKit {
  constructor() {
    this.ctx = null
    this.master = null
    this.enabled = localStorage.getItem("typingSoundEnabled") !== "false"
    this.theme = localStorage.getItem("typingSoundTheme") || "default"
    if (!MELODIES.hasOwnProperty(this.theme)) this.theme = "default"
    this.combo = 0
    this.melodyStep = 0
  }

  toggle() {
    this.enabled = !this.enabled
    localStorage.setItem("typingSoundEnabled", String(this.enabled))
    return this.enabled
  }

  setTheme(key) {
    if (!MELODIES.hasOwnProperty(key)) return
    this.theme = key
    this.melodyStep = 0
    localStorage.setItem("typingSoundTheme", key)
  }

  // テーマを選んだ直後に、その音色を1音だけ試聴させる
  preview() {
    if (this.theme === "default") {
      this.tone({ frequency: PENTATONIC[2], duration: 0.18, type: "triangle", gain: 0.09 })
    } else if (this.theme === "piano") {
      this.pianoNote(noteToFrequency("C5"))
    } else {
      this.pianoNote(noteToFrequency(MELODIES[this.theme].notes[0]))
    }
  }

  ensureContext() {
    if (!this.ctx) {
      const AudioContextClass = window.AudioContext || window.webkitAudioContext
      if (!AudioContextClass) return null
      this.ctx = new AudioContextClass()

      // 全体の音量とほんのり残響。単音のピコピコ感が消えて厚みが出る。
      this.master = this.ctx.createGain()
      this.master.gain.value = 0.9
      this.master.connect(this.ctx.destination)

      const convolver = this.ctx.createConvolver()
      convolver.buffer = this.buildReverb(1.1)
      const wet = this.ctx.createGain()
      wet.gain.value = 0.35
      convolver.connect(wet)
      wet.connect(this.ctx.destination)
      this.reverb = convolver
    }
    if (this.ctx.state === "suspended") this.ctx.resume()
    return this.ctx
  }

  // 短いノイズを減衰させて簡易的な残響を作る
  buildReverb(seconds) {
    const rate = this.ctx.sampleRate
    const length = Math.floor(rate * seconds)
    const buffer = this.ctx.createBuffer(2, length, rate)
    for (let ch = 0; ch < 2; ch++) {
      const data = buffer.getChannelData(ch)
      for (let i = 0; i < length; i++) {
        data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, 2.5)
      }
    }
    return buffer
  }

  tone({ frequency, duration, type = "sine", gain = 0.06, delay = 0, slideTo = null }) {
    if (!this.enabled) return
    const ctx = this.ensureContext()
    if (!ctx) return

    const osc = ctx.createOscillator()
    const amp = ctx.createGain()
    osc.type = type
    osc.connect(amp)
    amp.connect(this.master)
    amp.connect(this.reverb)

    const start = ctx.currentTime + delay
    osc.frequency.setValueAtTime(frequency, start)
    if (slideTo) osc.frequency.exponentialRampToValueAtTime(slideTo, start + duration)

    // 立ち上がりを一瞬にして、余韻を残すと打鍵感が出る
    amp.gain.setValueAtTime(0.0001, start)
    amp.gain.exponentialRampToValueAtTime(gain, start + 0.008)
    amp.gain.exponentialRampToValueAtTime(0.0001, start + duration)

    osc.start(start)
    osc.stop(start + duration + 0.02)
  }

  // 電子ピアノ風の音。倍音を重ねて減衰させると鍵盤らしい響きになる
  pianoNote(frequency, delay = 0) {
    const harmonics = [
      { ratio: 1, gain: 0.11, duration: 1.5, type: "triangle" },
      { ratio: 2, gain: 0.045, duration: 0.9, type: "sine" },
      { ratio: 3, gain: 0.02, duration: 0.6, type: "sine" },
      { ratio: 4, gain: 0.012, duration: 0.4, type: "sine" }
    ]
    harmonics.forEach((h) => {
      this.tone({
        frequency: frequency * h.ratio,
        duration: h.duration,
        type: h.type,
        gain: h.gain,
        delay
      })
    })
  }

  // 正解音。テーマによって鳴らし方を変える
  correctKey() {
    if (this.theme === "default") {
      // 打つほど音階が上がっていき、ノってくる感覚を出す
      const step = Math.min(this.combo, PENTATONIC.length - 1)
      const frequency = PENTATONIC[step]
      this.tone({ frequency, duration: 0.18, type: "triangle", gain: 0.09 })
      this.tone({ frequency: frequency * 2, duration: 0.12, type: "sine", gain: 0.035 })
    } else if (this.theme === "piano") {
      // 鍵盤を左から右へ順に叩いていくイメージ
      const note = PIANO_SCALE[this.melodyStep % PIANO_SCALE.length]
      this.pianoNote(noteToFrequency(note))
      this.melodyStep++
    } else {
      // 1打ごとにメロディが1音ずつ進む
      const melody = MELODIES[this.theme]
      const note = melody.notes[this.melodyStep % melody.notes.length]
      this.pianoNote(noteToFrequency(note))
      this.melodyStep++
    }

    this.combo++
    // コンボが乗ったら節目でご褒美の和音(デフォルトのみ)
    if (this.theme === "default" && this.combo > 0 && this.combo % 8 === 0) this.comboChord()
  }

  comboChord() {
    const base = 523.25
    ;[1, 1.25, 1.5].forEach((ratio, i) => {
      this.tone({
        frequency: base * ratio * 2,
        duration: 0.35,
        type: "sine",
        gain: 0.05,
        delay: i * 0.04
      })
    })
  }

  // ミス: コンボが途切れる。下降する音で「外した」感を出す
  // メロディは進めない。間違えた分だけ曲が止まる仕組みにして、正確さを促す。
  wrongKey() {
    this.combo = 0
    this.tone({ frequency: 320, duration: 0.22, type: "sawtooth", gain: 0.07, slideTo: 90 })
    this.tone({ frequency: 160, duration: 0.18, type: "square", gain: 0.05 })
  }

  reset() {
    this.combo = 0
    this.melodyStep = 0
  }

  // クリア: 駆け上がってから和音で締めるファンファーレ
  complete(perfect = false) {
    if (!this.enabled) return
    const scale = [523.25, 659.25, 783.99, 1046.5, 1318.51]

    scale.forEach((frequency, i) => {
      this.tone({
        frequency,
        duration: 0.3,
        type: "triangle",
        gain: 0.09,
        delay: i * 0.075
      })
      this.tone({
        frequency: frequency * 2,
        duration: 0.22,
        type: "sine",
        gain: 0.04,
        delay: i * 0.075
      })
    })

    // 最後に厚い和音を鳴らして締める
    const finalDelay = scale.length * 0.075 + 0.05
    ;[523.25, 659.25, 783.99, 1046.5].forEach((frequency) => {
      this.tone({
        frequency,
        duration: perfect ? 1.4 : 0.9,
        type: "triangle",
        gain: 0.07,
        delay: finalDelay
      })
    })

    // ノーミスならさらにキラキラを追加
    if (perfect) {
      ;[1567.98, 2093.0, 2637.02].forEach((frequency, i) => {
        this.tone({
          frequency,
          duration: 0.5,
          type: "sine",
          gain: 0.045,
          delay: finalDelay + 0.12 + i * 0.09
        })
      })
    }
  }
}

export { SoundKit, SOUND_THEMES }
