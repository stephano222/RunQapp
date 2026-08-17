// 全ページで流せる背景音楽。
// 音源ファイルは持たず、Web Audio APIで和音を組み立てて鳴らしている。
// 学習の邪魔にならないよう、音量は控えめ、進行はゆっくりにしてある。

// 曲は複数用意し、ページを開くたびにランダムで1つ選ぶ。
// いずれも実在の楽曲を引用するのではなく、その様式に沿って自前で組み立てている。
const TRACKS = [
  {
    name: "ミサ",
    // グレゴリオ聖歌に由来するドリア旋法。完全五度を土台にした素朴な響き。
    chords: [
      [146.83, 220.0, 293.66], // D + 完全五度(オルガヌムの基本形)
      [174.61, 261.63, 349.23], // F
      [196.0, 293.66, 392.0], // G
      [146.83, 220.0, 293.66], // D に戻る
      [130.81, 196.0, 261.63], // C
      [174.61, 261.63, 349.23] // F
    ],
    melody: [293.66, 329.63, 293.66, 261.63, 293.66, 349.23, 329.63, 293.66],
    seconds: 4.5,
    reverb: 3.5,
    wave: "sine"
  },
  {
    name: "森のしずく",
    // 明るい長調。木漏れ日のような穏やかな進行(I - vi - IV - V)。
    chords: [
      [261.63, 329.63, 392.0], // C
      [220.0, 261.63, 329.63], // Am
      [174.61, 220.0, 261.63], // F
      [196.0, 246.94, 293.66] // G
    ],
    melody: [523.25, 587.33, 659.25, 587.33, 523.25, 493.88, 523.25, 587.33],
    seconds: 3.2,
    reverb: 1.6,
    wave: "sine"
  },
  {
    name: "夜のしじま",
    // 短調。深い時間に合う、静かで少し陰のある響き。
    chords: [
      [220.0, 261.63, 329.63], // Am
      [174.61, 220.0, 261.63], // F
      [196.0, 246.94, 293.66], // G
      [164.81, 196.0, 246.94] // Em
    ],
    melody: [440.0, 392.0, 349.23, 329.63, 349.23, 392.0, 440.0, 493.88],
    seconds: 4.0,
    reverb: 2.6,
    wave: "triangle"
  },
  {
    name: "陽だまり",
    // ペンタトニック。素朴で童謡のような親しみやすい響き。
    chords: [
      [261.63, 392.0, 523.25], // C
      [293.66, 440.0, 587.33], // D
      [349.23, 523.25, 698.46], // F
      [261.63, 392.0, 523.25] // C
    ],
    melody: [523.25, 587.33, 698.46, 783.99, 698.46, 587.33, 523.25, 440.0],
    seconds: 3.6,
    reverb: 1.8,
    wave: "sine"
  }
]

class Bgm {
  constructor(button) {
    this.button = button
    this.ctx = null
    this.timer = null
    this.index = 0
    this.playing = false

    // ページを開くたびに曲を選び直す。
    // 直前と同じ曲は避けて、移動したことが耳でも分かるようにする。
    this.track = this.pickTrack()

    this.button.addEventListener("click", () => this.toggle())
    this.updateLabel()
    this.resumeIfEnabled()
  }

  pickTrack() {
    const previous = sessionStorage.getItem("bgmTrack")
    const candidates = TRACKS.filter((t) => t.name !== previous)
    const pool = candidates.length > 0 ? candidates : TRACKS

    const track = pool[Math.floor(Math.random() * pool.length)]
    sessionStorage.setItem("bgmTrack", track.name)
    return track
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

    // 石造りの聖堂のような長い残響を作る。
    // ミサ曲の響きは、この残響があって初めてそれらしくなる。
    const convolver = this.ctx.createConvolver()
    convolver.buffer = this.buildReverb(this.track.reverb)
    const wet = this.ctx.createGain()
    wet.gain.value = this.track.reverb > 2.5 ? 0.55 : 0.32
    convolver.connect(wet)
    wet.connect(this.ctx.destination)
    this.reverb = convolver

    return this.ctx
  }

  // 減衰するノイズから簡易的な残響を作る
  buildReverb(seconds) {
    const rate = this.ctx.sampleRate
    const length = Math.floor(rate * seconds)
    const buffer = this.ctx.createBuffer(2, length, rate)

    for (let ch = 0; ch < 2; ch++) {
      const data = buffer.getChannelData(ch)
      for (let i = 0; i < length; i++) {
        data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, 2.2)
      }
    }

    return buffer
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
    this.timer = setInterval(() => this.playChord(), this.track.seconds * 1000)
  }

  playChord() {
    if (!this.playing) return

    const chord = this.track.chords[this.index % this.track.chords.length]
    this.index++

    chord.forEach((frequency, i) => {
      // 和音の音を少しずつずらして鳴らすと、機械的な響きが和らぐ
      this.playTone(frequency, i * 0.08)
      // 1オクターブ上をごく小さく重ねて広がりを出す
      this.playTone(frequency * 2, i * 0.08, 0.22)
    })

    // 和音の上に聖歌の旋律を1音ずつ乗せていく
    const note = this.track.melody[(this.index - 1) % this.track.melody.length]
    this.playTone(note, 0.5, 0.45)
  }

  playTone(frequency, delay, volumeRatio = 1) {
    const ctx = this.ctx
    const osc = ctx.createOscillator()
    const amp = ctx.createGain()

    osc.type = this.track.wave
    osc.frequency.value = frequency
    osc.connect(amp)
    amp.connect(this.master)

    const start = ctx.currentTime + delay
    const duration = this.track.seconds * 0.95

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
    // 再生中は何の曲が流れているか分かるようにする
    this.button.textContent = this.playing ? `♪ ${this.track.name}` : "♪ BGM OFF"
    this.button.title = this.playing ? `${this.track.name}を再生中(押すと停止)` : "BGMを再生する"
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
