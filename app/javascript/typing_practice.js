// タイピング練習ウィジェット
// レベルごとの見せ方:
//   easy(優しい)   = お手本を薄く表示してなぞる
//   normal(普通)   = 次の1文字だけヒント表示
//   hard(難しい)   = お手本は一切表示せず、自分の入力だけを見て打つ

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

function escapeHtml(char) {
  if (char === "&") return "&amp;"
  if (char === "<") return "&lt;"
  if (char === ">") return "&gt;"
  return char
}

function renderChar(char, className) {
  const display = char === "\n" ? "\n" : char === " " ? " " : escapeHtml(char)
  return `<span class="${className}">${display}</span>`
}

class TypingApp {
  constructor(root) {
    this.root = root
    const dataScript = document.getElementById("snippet-data")
    this.data = JSON.parse(dataScript.textContent)
    this.target = this.data.code
    this.level = this.data.level

    this.targetDisplay = root.querySelector("#target-display")
    this.typedDisplay = root.querySelector("#typed-display")
    this.input = root.querySelector("#typing-input")
    this.progressBar = root.querySelector("#progress-bar")
    this.statAccuracy = root.querySelector("#stat-accuracy")
    this.statMistakes = root.querySelector("#stat-mistakes")
    this.statTime = root.querySelector("#stat-time")
    this.soundToggle = root.querySelector("#sound-toggle")
    this.resetButton = root.querySelector("#reset-button")
    this.revealToggle = root.querySelector("#reveal-toggle")
    this.themeSelect = root.querySelector("#sound-theme")

    this.sound = new SoundKit()
    this.previousValue = ""
    this.startTime = null
    this.mistakeCount = 0
    this.finished = false
    this.timerId = null
    // 優しいレベルは最初からお手本が出ているので、押した状態から始める
    this.revealed = this.level === "easy"

    this.bind()
    this.buildThemeOptions()
    this.updateSoundToggleLabel()
    this.updateRevealToggleLabel()
    this.renderTarget("")
    this.input.focus()
  }

  buildThemeOptions() {
    if (!this.themeSelect) return
    this.themeSelect.innerHTML = SOUND_THEMES.map(
      (t) => `<option value="${t.key}">${t.label}</option>`
    ).join("")
    this.themeSelect.value = this.sound.theme
  }

  bind() {
    this.input.addEventListener("input", () => this.handleInput())
    this.soundToggle.addEventListener("click", () => {
      const enabled = this.sound.toggle()
      this.updateSoundToggleLabel(enabled)
    })
    this.revealToggle.addEventListener("click", () => this.toggleReveal())
    if (this.themeSelect) {
      this.themeSelect.addEventListener("change", (event) => {
        this.sound.setTheme(event.target.value)
        this.sound.preview()
        this.input.focus()
      })
    }
    this.resetButton.addEventListener("click", () => this.reset())
    this.root.addEventListener("click", (event) => {
      if (event.target.closest("button")) return
      this.input.focus()
    })
  }

  updateSoundToggleLabel() {
    this.soundToggle.textContent = this.sound.enabled ? "🔊 効果音ON" : "🔇 効果音OFF"
  }

  toggleReveal() {
    this.revealed = !this.revealed
    this.updateRevealToggleLabel()
    this.renderTarget(this.input.value)
    this.input.focus()
  }

  updateRevealToggleLabel() {
    this.revealToggle.textContent = this.revealed ? "👁 お手本を隠す" : "👁 お手本を見る"
    this.revealToggle.classList.toggle("active", this.revealed)
  }

  reset() {
    this.finished = false
    this.previousValue = ""
    this.mistakeCount = 0
    this.startTime = null
    this.sound.reset()
    this.input.value = ""
    this.input.disabled = false
    this.stopTimer()
    this.statTime.textContent = "0.0秒"
    this.renderTarget("")
    this.input.focus()
  }

  startTimer() {
    if (this.timerId) return
    this.timerId = setInterval(() => {
      const elapsed = (performance.now() - this.startTime) / 1000
      this.statTime.textContent = `${elapsed.toFixed(1)}秒`
    }, 100)
  }

  stopTimer() {
    if (this.timerId) {
      clearInterval(this.timerId)
      this.timerId = null
    }
  }

  handleInput() {
    if (this.finished) return

    const value = this.input.value

    if (this.startTime === null && value.length > 0) {
      this.startTime = performance.now()
      this.startTimer()
    }

    if (value.length > this.previousValue.length) {
      const addedChars = value.slice(this.previousValue.length)
      let hadMistake = false
      for (let i = 0; i < addedChars.length; i++) {
        const pos = this.previousValue.length + i
        const expected = this.target[pos]
        if (addedChars[i] === expected) {
          this.sound.correctKey()
        } else {
          this.mistakeCount++
          hadMistake = true
        }
      }
      if (hadMistake) this.sound.wrongKey()
    }

    this.previousValue = value
    this.renderTarget(value)
    this.updateStats(value)

    if (value.length >= this.target.length) {
      this.finish(value)
    }
  }

  updateStats(value) {
    const total = this.target.length
    const typed = Math.min(value.length, total)
    let correct = 0
    for (let i = 0; i < typed; i++) {
      if (value[i] === this.target[i]) correct++
    }
    const accuracy = typed === 0 ? 100 : Math.round((correct / typed) * 1000) / 10
    this.statAccuracy.textContent = `${accuracy}%`
    this.statMistakes.textContent = `${this.mistakeCount}`
    this.progressBar.style.width = `${Math.min((value.length / total) * 100, 100)}%`
  }

  // お手本ボタンで表示中は、レベルに関わらず easy と同じ見え方にする
  displayMode() {
    return this.revealed ? "easy" : this.level
  }

  renderTarget(value) {
    const total = this.target.length
    const mode = this.displayMode()
    let html = ""

    for (let i = 0; i < total; i++) {
      const targetChar = this.target[i]
      const typedChar = value[i]
      let className = "char"

      if (typedChar !== undefined) {
        className += typedChar === targetChar ? " char-correct" : " char-incorrect"
      } else if (i === value.length) {
        className += " char-current"
      } else {
        className += " char-pending"
      }

      if (mode === "easy") {
        html += renderChar(targetChar, className)
      } else if (mode === "normal") {
        if (typedChar !== undefined) {
          html += renderChar(targetChar, className)
        } else if (i === value.length) {
          html += renderChar(targetChar, `${className} char-hint`)
        } else if (targetChar === "\n") {
          html += "<br>"
        } else if (targetChar === " ") {
          html += renderChar(" ", "char char-masked")
        } else {
          html += renderChar("・", "char char-masked")
        }
      }
      // hard は target-display 自体を使わない
    }

    if (mode === "hard") {
      this.targetDisplay.classList.add("d-none")
      this.typedDisplay.classList.remove("d-none")
      this.typedDisplay.innerHTML = this.renderTypedOnly(value)
    } else {
      this.typedDisplay.classList.add("d-none")
      this.targetDisplay.classList.remove("d-none")
      this.targetDisplay.innerHTML = html
    }
  }

  renderTypedOnly(value) {
    let html = ""
    for (let i = 0; i < value.length; i++) {
      const className = value[i] === this.target[i] ? "char char-correct" : "char char-incorrect"
      html += renderChar(value[i], className)
    }
    html += renderChar("", "char char-current")
    return html || '<span class="text-muted">ここに入力した文字が表示されます…</span>'
  }

  async finish(value) {
    this.finished = true
    this.stopTimer()
    this.input.disabled = true

    const durationMs = this.startTime ? Math.round(performance.now() - this.startTime) : 0
    const total = this.target.length
    let correct = 0
    for (let i = 0; i < total; i++) {
      if (value[i] === this.target[i]) correct++
    }

    // ノーミスで打ち切れたときは、より豪華なファンファーレを鳴らす
    this.sound.complete(this.mistakeCount === 0 && correct === total)
    const accuracy = Math.round((correct / total) * 1000) / 10

    const response = await fetch("/attempts", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": this.data.csrfToken,
      },
      body: JSON.stringify({
        attempt: {
          snippet_id: this.data.snippetId,
          level: this.level,
          input_text: value,
          accuracy: accuracy,
          mistake_count: this.mistakeCount,
          duration_ms: durationMs,
          correct: value === this.target,
        },
      }),
    })

    if (response.ok) {
      const json = await response.json()
      window.location.href = json.redirect_url
    }
  }
}

function initTypingApp() {
  const root = document.querySelector("#typing-app")
  if (root) new TypingApp(root)
}

document.addEventListener("DOMContentLoaded", initTypingApp)
document.addEventListener("turbo:load", initTypingApp)
