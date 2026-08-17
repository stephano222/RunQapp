// クリア後のおまけ。遊んでも遊ばなくても学習には影響しない。
// どんぐりを撃ち上げて、降りてくる蜂を落とす簡単なシューティング。

const GAME_SECONDS = 20
const PLAYER_SIZE = 34
const BULLET_SPEED = 380 // px/秒
const FIRE_INTERVAL = 260 // ミリ秒
const ENEMY_KINDS = [
  { icon: "🐝", speed: 55, point: 1 },
  { icon: "🦟", speed: 85, point: 2 },
  { icon: "🐛", speed: 35, point: 1 }
]

class ShootingGame {
  constructor(root) {
    this.root = root
    this.startButton = root.querySelector("#game-start")
    this.stage = root.querySelector("#game-stage")
    this.panel = root.querySelector("#game-panel")
    this.scoreLabel = root.querySelector("#game-score")
    this.timeLabel = root.querySelector("#game-time")
    this.resultLabel = root.querySelector("#game-result")
    this.bestLabel = root.querySelector("#game-best")

    this.bullets = []
    this.enemies = []
    this.score = 0
    this.missed = 0
    this.running = false
    this.playerX = 0.5 // ステージ幅に対する割合で持つ

    this.startButton.addEventListener("click", () => this.start())
    this.bindAim()
    this.showBest()
  }

  best() {
    return Number(localStorage.getItem("shootingGameBest") || 0)
  }

  showBest() {
    const best = this.best()
    this.bestLabel.textContent = best > 0 ? `これまでの最高: ${best}点` : ""
  }

  // 指やマウスの位置に砲台を合わせる
  bindAim() {
    const aim = (clientX) => {
      const rect = this.stage.getBoundingClientRect()
      if (rect.width === 0) return
      const ratio = (clientX - rect.left) / rect.width
      this.playerX = Math.min(Math.max(ratio, 0.04), 0.96)
      this.drawPlayer()
    }

    this.stage.addEventListener("mousemove", (e) => aim(e.clientX))
    this.stage.addEventListener(
      "touchmove",
      (e) => {
        if (e.touches[0]) aim(e.touches[0].clientX)
        e.preventDefault()
      },
      { passive: false }
    )
    this.stage.addEventListener(
      "touchstart",
      (e) => {
        if (e.touches[0]) aim(e.touches[0].clientX)
      },
      { passive: true }
    )
  }

  start() {
    if (this.running) return
    this.running = true
    this.score = 0
    this.missed = 0
    this.bullets = []
    this.enemies = []
    this.remaining = GAME_SECONDS

    this.panel.classList.remove("d-none")
    this.resultLabel.textContent = ""
    this.startButton.textContent = "プレイ中…"
    this.startButton.disabled = true
    this.stage.innerHTML = ""

    this.player = document.createElement("div")
    this.player.className = "shooter-player"
    this.player.textContent = "🐿️"
    this.stage.appendChild(this.player)
    this.drawPlayer()

    this.updateLabels()

    this.timerId = setInterval(() => {
      this.remaining--
      this.updateLabels()
      if (this.remaining <= 0) this.finish()
    }, 1000)

    this.spawnId = setInterval(() => this.spawnEnemy(), 700)
    this.fireId = setInterval(() => this.fire(), FIRE_INTERVAL)

    this.lastFrame = performance.now()
    this.loop()
  }

  drawPlayer() {
    if (!this.player) return
    this.player.style.left = `calc(${this.playerX * 100}% - ${PLAYER_SIZE / 2}px)`
  }

  updateLabels() {
    this.scoreLabel.textContent = `${this.score}点`
    this.timeLabel.textContent = `${Math.max(this.remaining, 0)}秒`
  }

  fire() {
    if (!this.running) return
    const rect = this.stage.getBoundingClientRect()

    const el = document.createElement("div")
    el.className = "shooter-bullet"
    el.textContent = "🌰"
    this.stage.appendChild(el)

    const bullet = { el, x: this.playerX * rect.width, y: rect.height - PLAYER_SIZE - 6 }
    el.style.left = `${bullet.x - 8}px`
    el.style.top = `${bullet.y}px`
    this.bullets.push(bullet)
  }

  spawnEnemy() {
    if (!this.running) return
    const rect = this.stage.getBoundingClientRect()
    const kind = ENEMY_KINDS[Math.floor(Math.random() * ENEMY_KINDS.length)]

    const el = document.createElement("div")
    el.className = "shooter-enemy"
    el.textContent = kind.icon
    this.stage.appendChild(el)

    const enemy = {
      el,
      kind,
      x: 16 + Math.random() * Math.max(rect.width - 48, 10),
      y: -20
    }
    el.style.left = `${enemy.x}px`
    el.style.top = `${enemy.y}px`
    this.enemies.push(enemy)
  }

  loop() {
    if (!this.running) return

    const now = performance.now()
    const delta = Math.min((now - this.lastFrame) / 1000, 0.05)
    this.lastFrame = now

    const rect = this.stage.getBoundingClientRect()

    // 弾は上へ
    this.bullets = this.bullets.filter((b) => {
      b.y -= BULLET_SPEED * delta
      if (b.y < -20) {
        b.el.remove()
        return false
      }
      b.el.style.top = `${b.y}px`
      return true
    })

    // 敵は下へ。下まで到達したら取り逃がし
    this.enemies = this.enemies.filter((e) => {
      e.y += e.kind.speed * delta
      if (e.y > rect.height) {
        e.el.remove()
        this.missed++
        return false
      }
      e.el.style.top = `${e.y}px`
      return true
    })

    this.checkHits()

    this.frameId = requestAnimationFrame(() => this.loop())
  }

  checkHits() {
    const hitBullets = new Set()
    const hitEnemies = new Set()

    this.enemies.forEach((enemy, ei) => {
      this.bullets.forEach((bullet, bi) => {
        if (hitBullets.has(bi) || hitEnemies.has(ei)) return
        // 矩形どうしの簡易な当たり判定
        if (Math.abs(enemy.x - bullet.x) < 24 && Math.abs(enemy.y - bullet.y) < 24) {
          hitBullets.add(bi)
          hitEnemies.add(ei)
          this.score += enemy.kind.point
          this.burst(enemy.x, enemy.y)
        }
      })
    })

    if (hitEnemies.size === 0) return

    this.bullets = this.bullets.filter((b, i) => {
      if (!hitBullets.has(i)) return true
      b.el.remove()
      return false
    })
    this.enemies = this.enemies.filter((e, i) => {
      if (!hitEnemies.has(i)) return true
      e.el.remove()
      return false
    })

    this.updateLabels()
  }

  burst(x, y) {
    const el = document.createElement("div")
    el.className = "shooter-burst"
    el.textContent = "✨"
    el.style.left = `${x - 10}px`
    el.style.top = `${y}px`
    this.stage.appendChild(el)
    setTimeout(() => el.remove(), 320)
  }

  finish() {
    this.running = false
    clearInterval(this.timerId)
    clearInterval(this.spawnId)
    clearInterval(this.fireId)
    if (this.frameId) cancelAnimationFrame(this.frameId)
    this.stage.innerHTML = ""

    const best = this.best()
    if (this.score > best) {
      localStorage.setItem("shootingGameBest", String(this.score))
      this.resultLabel.textContent = `${this.score}点！自己ベスト更新です`
    } else {
      this.resultLabel.textContent = `${this.score}点(取り逃がし ${this.missed}匹)`
    }

    this.showBest()
    this.startButton.textContent = "もう一度あそぶ"
    this.startButton.disabled = false
  }
}

function initMiniGame() {
  const root = document.querySelector("#mini-game")
  if (root) new ShootingGame(root)
}

document.addEventListener("DOMContentLoaded", initMiniGame)
document.addEventListener("turbo:load", initMiniGame)
