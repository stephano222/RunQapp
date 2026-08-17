// 写経モード。
// 採点はせず、1行ずつ書き写して進むことだけに集中できるようにしている。
// 長いコードを想定し、行単位で「今どこを写しているか」が分かる作りにした。

function escapeHtml(text) {
  return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
}

class Shakyo {
  constructor(root) {
    this.root = root
    this.lines = JSON.parse(document.getElementById("shakyo-data").textContent).code.split("\n")

    this.source = root.querySelector("#shakyo-source")
    this.input = root.querySelector("#shakyo-input")
    this.bar = root.querySelector("#shakyo-bar")
    this.progress = root.querySelector("#shakyo-progress")
    this.doneBox = root.querySelector("#shakyo-done")
    this.resetButton = root.querySelector("#shakyo-reset")

    this.current = 0

    this.input.addEventListener("input", () => this.render())
    this.input.addEventListener("keydown", (e) => this.handleKey(e))
    this.resetButton.addEventListener("click", () => this.reset())

    this.render()
    this.input.focus()
  }

  // 空行は写す必要がないので自動で飛ばす
  skipBlankLines() {
    while (this.current < this.lines.length && this.lines[this.current].trim() === "") {
      this.current++
    }
  }

  handleKey(event) {
    if (event.key !== "Enter") return
    event.preventDefault()

    const expected = this.lines[this.current]
    if (expected === undefined) return

    // 完全に一致していなくても、写す意思があれば進めるようにする。
    // 写経は正確さを競うものではなく、手を動かすことが目的のため。
    this.current++
    this.skipBlankLines()
    this.input.value = ""
    this.render()

    if (this.current >= this.lines.length) this.finish()
  }

  render() {
    const html = this.lines
      .map((line, i) => {
        const number = String(i + 1).padStart(String(this.lines.length).length, " ")
        const text = escapeHtml(line) || " "

        let cls = "shakyo-line"
        if (i < this.current) cls += " shakyo-line-done"
        else if (i === this.current) cls += " shakyo-line-current"

        return `<span class="${cls}"><span class="shakyo-number">${number}</span>${text}</span>`
      })
      .join("\n")

    this.source.innerHTML = html

    const done = Math.min(this.current, this.lines.length)
    const percent = this.lines.length === 0 ? 100 : (done / this.lines.length) * 100
    this.bar.style.width = `${percent}%`
    this.progress.textContent = `${done} / ${this.lines.length} 行`

    this.scrollToCurrent()
  }

  // 今写している行が画面から外れないよう追従させる
  scrollToCurrent() {
    const currentLine = this.source.querySelector(".shakyo-line-current")
    if (!currentLine) return

    const box = this.source.getBoundingClientRect()
    const line = currentLine.getBoundingClientRect()
    if (line.top < box.top || line.bottom > box.bottom) {
      currentLine.scrollIntoView({ block: "center" })
    }
  }

  finish() {
    this.doneBox.classList.remove("d-none")
    this.input.disabled = true
  }

  reset() {
    this.current = 0
    this.skipBlankLines()
    this.input.value = ""
    this.input.disabled = false
    this.doneBox.classList.add("d-none")
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
