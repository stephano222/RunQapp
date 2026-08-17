// クリア後のおまけ。遊んでも遊ばなくても学習には影響しない。
// 10秒間、次々に現れるどんぐりを拾う簡単な息抜きゲーム。

const GAME_SECONDS = 10
const ITEMS = ["🌰", "🌰", "🌰", "🍄", "🍁"]
const BOMB = "🐝"

class AcornGame {
  constructor(root) {
    this.root = root
    this.startButton = root.querySelector("#game-start")
    this.stage = root.querySelector("#game-stage")
    this.panel = root.querySelector("#game-panel")
    this.scoreLabel = root.querySelector("#game-score")
    this.timeLabel = root.querySelector("#game-time")
    this.resultLabel = root.querySelector("#game-result")
    this.bestLabel = root.querySelector("#game-best")

    this.score = 0
    this.remaining = GAME_SECONDS
    this.timerId = null
    this.spawnId = null
    this.running = false

    this.startButton.addEventListener("click", () => this.start())
    this.showBest()
  }

  best() {
    return Number(localStorage.getItem("acornGameBest") || 0)
  }

  showBest() {
    const best = this.best()
    this.bestLabel.textContent = best > 0 ? `これまでの最高: ${best}個` : ""
  }

  start() {
    if (this.running) return
    this.running = true
    this.score = 0
    this.remaining = GAME_SECONDS

    this.panel.classList.remove("d-none")
    this.resultLabel.textContent = ""
    this.startButton.textContent = "プレイ中…"
    this.startButton.disabled = true
    this.stage.innerHTML = ""
    this.updateLabels()

    this.timerId = setInterval(() => {
      this.remaining--
      this.updateLabels()
      if (this.remaining <= 0) this.finish()
    }, 1000)

    this.spawnId = setInterval(() => this.spawn(), 550)
    this.spawn()
  }

  updateLabels() {
    this.scoreLabel.textContent = `${this.score}個`
    this.timeLabel.textContent = `${Math.max(this.remaining, 0)}秒`
  }

  spawn() {
    if (!this.running) return

    const isBomb = Math.random() < 0.18
    const item = document.createElement("button")
    item.type = "button"
    item.className = "acorn-item"
    item.textContent = isBomb ? BOMB : ITEMS[Math.floor(Math.random() * ITEMS.length)]

    // ステージ内のランダムな位置に出す(端で見切れないよう内側に寄せる)
    item.style.left = `${8 + Math.random() * 78}%`
    item.style.top = `${10 + Math.random() * 68}%`

    const remove = () => item.remove()

    item.addEventListener("click", (event) => {
      event.stopPropagation()
      if (!this.running) return
      this.score += isBomb ? -2 : 1
      if (this.score < 0) this.score = 0
      item.classList.add(isBomb ? "acorn-bad" : "acorn-got")
      this.updateLabels()
      setTimeout(remove, 150)
    })

    this.stage.appendChild(item)
    // 拾われなくても一定時間で消える
    setTimeout(remove, 1400)
  }

  finish() {
    this.running = false
    clearInterval(this.timerId)
    clearInterval(this.spawnId)
    this.stage.innerHTML = ""

    const best = this.best()
    if (this.score > best) {
      localStorage.setItem("acornGameBest", String(this.score))
      this.resultLabel.textContent = `${this.score}個！自己ベスト更新です`
    } else {
      this.resultLabel.textContent = `${this.score}個 拾いました`
    }

    this.showBest()
    this.startButton.textContent = "もう一度あそぶ"
    this.startButton.disabled = false
  }
}

function initMiniGame() {
  const root = document.querySelector("#mini-game")
  if (root) new AcornGame(root)
}

document.addEventListener("DOMContentLoaded", initMiniGame)
document.addEventListener("turbo:load", initMiniGame)
