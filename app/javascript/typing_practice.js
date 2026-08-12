// タイピング練習ウィジェット
// レベルごとの見せ方:
//   easy(優しい)   = お手本を薄く表示してなぞる
//   normal(普通)   = 次の1文字だけヒント表示
//   hard(難しい)   = お手本は一切表示せず、自分の入力だけを見て打つ

class SoundKit {
  constructor() {
    this.ctx = null
    this.enabled = localStorage.getItem("typingSoundEnabled") !== "false"
  }

  toggle() {
    this.enabled = !this.enabled
    localStorage.setItem("typingSoundEnabled", String(this.enabled))
    return this.enabled
  }

  ensureContext() {
    if (!this.ctx) {
      const AudioContextClass = window.AudioContext || window.webkitAudioContext
      if (!AudioContextClass) return null
      this.ctx = new AudioContextClass()
    }
    if (this.ctx.state === "suspended") this.ctx.resume()
    return this.ctx
  }

  beep({ frequency, duration, type = "sine", gain = 0.06 }) {
    if (!this.enabled) return
    const ctx = this.ensureContext()
    if (!ctx) return

    const oscillator = ctx.createOscillator()
    const gainNode = ctx.createGain()
    oscillator.type = type
    oscillator.frequency.value = frequency
    gainNode.gain.value = gain
    oscillator.connect(gainNode)
    gainNode.connect(ctx.destination)

    const now = ctx.currentTime
    gainNode.gain.setValueAtTime(gain, now)
    gainNode.gain.exponentialRampToValueAtTime(0.0001, now + duration)
    oscillator.start(now)
    oscillator.stop(now + duration)
  }

  correctKey() {
    this.beep({ frequency: 720, duration: 0.05, type: "square", gain: 0.05 })
  }

  wrongKey() {
    this.beep({ frequency: 160, duration: 0.09, type: "sawtooth", gain: 0.06 })
  }

  complete() {
    if (!this.enabled) return
    const notes = [523.25, 659.25, 783.99]
    notes.forEach((frequency, i) => {
      setTimeout(() => this.beep({ frequency, duration: 0.18, type: "sine", gain: 0.05 }), i * 90)
    })
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

    this.sound = new SoundKit()
    this.previousValue = ""
    this.startTime = null
    this.mistakeCount = 0
    this.finished = false
    this.timerId = null

    this.bind()
    this.updateSoundToggleLabel()
    this.renderTarget("")
    this.input.focus()
  }

  bind() {
    this.input.addEventListener("input", () => this.handleInput())
    this.soundToggle.addEventListener("click", () => {
      const enabled = this.sound.toggle()
      this.updateSoundToggleLabel(enabled)
    })
    this.resetButton.addEventListener("click", () => this.reset())
    this.root.addEventListener("click", (event) => {
      if (event.target.closest("button")) return
      this.input.focus()
    })
  }

  updateSoundToggleLabel() {
    this.soundToggle.textContent = this.sound.enabled ? "🔊 効果音ON" : "🔇 効果音OFF"
  }

  reset() {
    this.finished = false
    this.previousValue = ""
    this.mistakeCount = 0
    this.startTime = null
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

  renderTarget(value) {
    const total = this.target.length
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

      if (this.level === "easy") {
        html += renderChar(targetChar, className)
      } else if (this.level === "normal") {
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

    if (this.level === "hard") {
      this.targetDisplay.classList.add("d-none")
      this.typedDisplay.classList.remove("d-none")
      this.typedDisplay.innerHTML = this.renderTypedOnly(value)
    } else {
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
    this.sound.complete()

    const durationMs = this.startTime ? Math.round(performance.now() - this.startTime) : 0
    const total = this.target.length
    let correct = 0
    for (let i = 0; i < total; i++) {
      if (value[i] === this.target[i]) correct++
    }
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
