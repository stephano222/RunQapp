// タイピング練習ウィジェット
// レベルごとの見せ方:
//   easy(優しい)   = お手本を薄く表示してなぞる
//   normal(普通)   = 次の1文字だけヒント表示
//   hard(難しい)   = お手本は一切表示せず、自分の入力だけを見て打つ

import { SoundKit, SOUND_THEMES } from "./sound_kit"


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
    // 優しいレベルではボタン自体を置いていないので存在確認してから繋ぐ
    if (this.revealToggle) {
      this.revealToggle.addEventListener("click", () => this.toggleReveal())
    }
    if (this.themeSelect) {
      this.themeSelect.addEventListener("change", (event) => {
        this.sound.setTheme(event.target.value)
        this.sound.preview()
      })
    }
    this.resetButton.addEventListener("click", () => this.reset())
    // 余白をタップしたら入力欄に戻す。ただし操作部品の上では邪魔しない
    // (セレクトを除外しないと、開いた瞬間にフォーカスを奪って閉じてしまう)
    this.root.addEventListener("click", (event) => {
      if (event.target.closest("button, select, option, label, a")) return
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
    if (!this.revealToggle) return
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
