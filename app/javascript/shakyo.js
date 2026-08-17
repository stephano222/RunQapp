// 写経モード。
// 練習モードと同じ「なぞって打つ」操作にしつつ、長いコードを想定して
// 1行ずつ進む形にしている。レベルと効果音も練習モードと揃えた。

import { SoundKit, SOUND_THEMES } from "./sound_kit"

function escapeHtml(char) {
  if (char === "&") return "&amp;"
  if (char === "<") return "&lt;"
  if (char === ">") return "&gt;"
  return char
}

function renderChar(char, className) {
  const display = char === " " ? " " : escapeHtml(char)
  return `<span class="${className}">${display}</span>`
}

class Shakyo {
  constructor(root) {
    this.root = root
    const data = JSON.parse(document.getElementById("shakyo-data").textContent)
    this.lines = data.code.split("\n")
    this.level = data.level

    this.source = root.querySelector("#shakyo-source")
    this.lineDisplay = root.querySelector("#shakyo-line")
    this.input = root.querySelector("#shakyo-input")
    this.bar = root.querySelector("#shakyo-bar")
    this.progress = root.querySelector("#shakyo-progress")
    this.accuracy = root.querySelector("#shakyo-accuracy")
    this.mistakes = root.querySelector("#shakyo-mistakes")
    this.doneBox = root.querySelector("#shakyo-done")
    this.resetButton = root.querySelector("#shakyo-reset")
    this.soundToggle = root.querySelector("#shakyo-sound")
    this.themeSelect = root.querySelector("#shakyo-theme")
    this.revealToggle = root.querySelector("#shakyo-reveal")

    this.sound = new SoundKit()
    this.current = 0
    this.previousValue = ""
    this.mistakeCount = 0
    this.typedCount = 0
    this.correctCount = 0
    // 優しいレベルは最初からお手本が出ている
    this.revealed = this.level === "easy"

    this.bind()
    this.buildThemeOptions()
    this.updateSoundLabel()
    this.updateRevealLabel()
    this.skipBlankLines()
    this.render()
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
    this.input.addEventListener("keydown", (e) => this.handleKey(e))
    this.resetButton.addEventListener("click", () => this.reset())

    this.soundToggle.addEventListener("click", () => {
      this.sound.toggle()
      this.updateSoundLabel()
    })

    if (this.themeSelect) {
      this.themeSelect.addEventListener("change", (event) => {
        this.sound.setTheme(event.target.value)
        this.sound.preview()
      })
    }

    if (this.revealToggle) {
      this.revealToggle.addEventListener("click", () => {
        this.revealed = !this.revealed
        this.updateRevealLabel()
        this.render()
        this.input.focus()
      })
    }

    this.root.addEventListener("click", (event) => {
      if (event.target.closest("button, select, option, label, a")) return
      this.input.focus()
    })
  }

  updateSoundLabel() {
    this.soundToggle.textContent = this.sound.enabled ? "🔊 効果音ON" : "🔇 効果音OFF"
  }

  updateRevealLabel() {
    if (!this.revealToggle) return
    this.revealToggle.textContent = this.revealed ? "👁 お手本を隠す" : "👁 お手本を見る"
  }

  // お手本ボタンで表示中は、レベルに関わらず easy と同じ見え方にする
  displayMode() {
    return this.revealed ? "easy" : this.level
  }

  // 空行は写す必要がないので自動で飛ばす
  skipBlankLines() {
    while (this.current < this.lines.length && this.lines[this.current].trim() === "") {
      this.current++
    }
  }

  currentLine() {
    return this.lines[this.current] ?? ""
  }

  handleInput() {
    const value = this.input.value
    const target = this.currentLine()

    // 増えた文字だけを見て、正誤の音を鳴らす
    if (value.length > this.previousValue.length) {
      const added = value.slice(this.previousValue.length)
      let hadMistake = false

      for (let i = 0; i < added.length; i++) {
        const pos = this.previousValue.length + i
        this.typedCount++

        if (added[i] === target[pos]) {
          this.correctCount++
          this.sound.correctKey()
        } else {
          this.mistakeCount++
          hadMistake = true
        }
      }

      if (hadMistake) this.sound.wrongKey()
    }

    this.previousValue = value
    this.render()
  }

  handleKey(event) {
    if (event.key !== "Enter") return
    event.preventDefault()

    if (this.current >= this.lines.length) return

    this.current++
    this.skipBlankLines()
    this.input.value = ""
    this.previousValue = ""
    this.render()

    if (this.current >= this.lines.length) this.finish()
  }

  render() {
    this.renderSource()
    this.renderCurrentLine()
    this.updateStats()
    this.scrollToCurrent()
  }

  // 全体のお手本。今写している行だけ強調する。
  renderSource() {
    const width = String(this.lines.length).length

    this.source.innerHTML = this.lines
      .map((line, i) => {
        const number = String(i + 1).padStart(width, " ")

        let cls = "shakyo-line"
        if (i < this.current) cls += " shakyo-line-done"
        else if (i === this.current) cls += " shakyo-line-current"

        // 難しいレベルでは、まだ写していない先の行は伏せる
        const hidden = this.displayMode() === "hard" && i > this.current
        const text = hidden ? "・".repeat(Math.min(line.trim().length, 30)) : escapeHtml(line) || " "

        return `<span class="${cls}"><span class="shakyo-number">${number}</span>${text}</span>`
      })
      .join("\n")
  }

  // 現在行のなぞり表示。練習モードと同じ見せ方をレベルごとに行う。
  renderCurrentLine() {
    const target = this.currentLine()
    const value = this.input.value
    const mode = this.displayMode()
    let html = ""

    for (let i = 0; i < target.length; i++) {
      const targetChar = target[i]
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
        } else if (targetChar === " ") {
          html += renderChar(" ", "char char-masked")
        } else {
          html += renderChar("・", "char char-masked")
        }
      }
    }

    if (mode === "hard") {
      // 打った文字だけを見せる
      let typed = ""
      for (let i = 0; i < value.length; i++) {
        const cls = value[i] === target[i] ? "char char-correct" : "char char-incorrect"
        typed += renderChar(value[i], cls)
      }
      typed += renderChar("", "char char-current")
      this.lineDisplay.innerHTML =
        typed || '<span class="text-muted">この行を記憶を頼りに入力してください…</span>'
    } else {
      this.lineDisplay.innerHTML = html || '<span class="text-muted">(空行)</span>'
    }
  }

  updateStats() {
    const done = Math.min(this.current, this.lines.length)
    const percent = this.lines.length === 0 ? 100 : (done / this.lines.length) * 100

    this.bar.style.width = `${percent}%`
    this.progress.textContent = `${done} / ${this.lines.length} 行`
    this.mistakes.textContent = `${this.mistakeCount}`

    const rate = this.typedCount === 0
      ? 100
      : Math.round((this.correctCount / this.typedCount) * 1000) / 10
    this.accuracy.textContent = `${rate}%`
  }

  // 今写している行が画面から外れないよう追従させる
  scrollToCurrent() {
    const line = this.source.querySelector(".shakyo-line-current")
    if (!line) return

    const box = this.source.getBoundingClientRect()
    const rect = line.getBoundingClientRect()
    if (rect.top < box.top || rect.bottom > box.bottom) {
      line.scrollIntoView({ block: "center" })
    }
  }

  finish() {
    this.doneBox.classList.remove("d-none")
    this.input.disabled = true
    this.sound.complete(this.mistakeCount === 0)
  }

  reset() {
    this.current = 0
    this.previousValue = ""
    this.mistakeCount = 0
    this.typedCount = 0
    this.correctCount = 0
    this.sound.reset()
    this.input.value = ""
    this.input.disabled = false
    this.doneBox.classList.add("d-none")
    this.skipBlankLines()
    this.render()
    this.input.focus()
  }
}

function initShakyo() {
  const root = document.querySelector("#shakyo-app")
  if (root) new Shakyo(root)
}

document.addEventListener("DOMContentLoaded", initShakyo)
document.addEventListener("turbo:load", initShakyo)
