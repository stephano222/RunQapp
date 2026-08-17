// 全ページで流せる背景音楽。
// 音源ファイルは持たず、Web Audio APIで和音を組み立てて鳴らしている。
// 学習の邪魔にならないよう、音量は控えめ、進行はゆっくりにしてある。

// ハ長調の落ち着いた進行(I - vi - IV - V)。
// どの和音からどこへ進んでも耳に馴染むので、繰り返しても飽きにくい。
const CHORDS = [
  [261.63, 329.63, 392.0], // C
  [220.0, 261.63, 329.63], // Am
  [174.61, 220.0, 261.63], // F
  [196.0, 246.94, 293.66] // G
]

const CHORD_SECONDS = 3.2

class Bgm {
  constructor(button) {
    this.button = button
    this.ctx = null
    this.timer = null
    this.index = 0
    this.playing = false

    this.button.addEventListener("click", () => this.toggle())
    this.updateLabel()
    this.resumeIfEnabled()
  }

  // ページを移動しても鳴り続けているように見せる。
  // 一度でも操作していればブラウザは音を許可するため、
  // 前回ONにしていた場合はそのまま再開してよい。
  resumeIfEnabled() {
    if (localStorage.getItem("bgmEnabled") !== "true") return

    this.start()

    // 移動直後などブラウザが音を止めている場合は、
    // 次に画面を触った時点で鳴らし直す
    if (this.ctx && this.ctx.state === "suspended") {
      const resume = () => {
        this.ctx.resume()
        document.removeEventListener("click", resume)
        document.removeEventListener("keydown", resume)
      }
      document.addEventListener("click", resume)
      document.addEventListener("keydown", resume)
    }
  }

  ensureContext() {
    if (this.ctx) return this.ctx

    const AudioContextClass = window.AudioContext || window.webkitAudioContext
    if (!AudioContextClass) return null

    this.ctx = new AudioContextClass()

    this.master = this.ctx.createGain()
    this.master.gain.value = 0.16 // 打鍵音より明らかに小さくする
    this.master.connect(this.ctx.destination)

    return this.ctx
  }

  toggle() {
    this.playing ? this.stop() : this.start()
  }

  start() {
    const ctx = this.ensureContext()
    if (!ctx) return
    if (ctx.state === "suspended") ctx.resume()

    this.playing = true
    localStorage.setItem("bgmEnabled", "true")
    this.updateLabel()

    this.playChord()
    this.timer = setInterval(() => this.playChord(), CHORD_SECONDS * 1000)
  }

  playChord() {
    if (!this.playing) return

    const chord = CHORDS[this.index % CHORDS.length]
    this.index++

    chord.forEach((frequency, i) => {
      // 和音の音を少しずつずらして鳴らすと、機械的な響きが和らぐ
      this.playTone(frequency, i * 0.06)
      // 1オクターブ上をごく小さく重ねて広がりを出す
      this.playTone(frequency * 2, i * 0.06, 0.25)
    })
  }

  playTone(frequency, delay, volumeRatio = 1) {
    const ctx = this.ctx
    const osc = ctx.createOscillator()
    const amp = ctx.createGain()

    osc.type = "sine"
    osc.frequency.value = frequency
    osc.connect(amp)
    amp.connect(this.master)

    const start = ctx.currentTime + delay
    const duration = CHORD_SECONDS * 0.95

    // ゆっくり立ち上げ、ゆっくり消す。急な音の変化を避ける。
    amp.gain.setValueAtTime(0.0001, start)
    amp.gain.exponentialRampToValueAtTime(0.18 * volumeRatio, start + 0.8)
    amp.gain.exponentialRampToValueAtTime(0.0001, start + duration)

    osc.start(start)
    osc.stop(start + duration + 0.1)
  }

  stop() {
    this.playing = false
    localStorage.setItem("bgmEnabled", "false")
    clearInterval(this.timer)
    this.timer = null
    this.updateLabel()
  }

  // 画面の切り替え時に呼ぶ。設定は変えずに音だけ止める。
  shutdown() {
    this.playing = false
    clearInterval(this.timer)
    this.timer = null
    if (this.ctx) {
      this.ctx.close()
      this.ctx = null
    }
  }

  updateLabel() {
    this.button.textContent = this.playing ? "♪ BGM ON" : "♪ BGM OFF"
    this.button.classList.toggle("bgm-on", this.playing)
  }
}

let currentBgm = null

function initBgm() {
  const button = document.querySelector("#bgm-toggle")
  if (!button) return

  // 画面が切り替わったら前の再生を止める。
  // 止めないと和音が二重に鳴って濁ってしまう。
  if (currentBgm) currentBgm.shutdown()

  currentBgm = new Bgm(button)
}

document.addEventListener("DOMContentLoaded", initBgm)
document.addEventListener("turbo:load", initBgm)
