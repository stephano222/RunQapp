// クリア後のおまけ。遊んでも遊ばなくても学習には影響しない。
// 4種類のゲームからランダムに1つ選ばれる。

// ============================================================
// 1. シューティング
// ============================================================

const SHOOT_SECONDS = 20
const PLAYER_SIZE = 34
const BULLET_SPEED = 380
const FIRE_INTERVAL = 260
const ENEMY_KINDS = [
  { icon: "🐝", speed: 55, point: 1 },
  { icon: "🦟", speed: 85, point: 2 },
  { icon: "🐛", speed: 35, point: 1 }
]

class ShootingGame {
  static title = "🌰 どんぐりシューティング"
  static hint = "指やマウスを左右に動かすと🐿️が移動し、どんぐりを自動で撃ちます。"
  static bestKey = "gameBestShooting"

  constructor(ui) {
    this.ui = ui
    this.bullets = []
    this.enemies = []
    this.playerX = 0.5
    this.bindAim()
  }

  bindAim() {
    const aim = (clientX) => {
      const rect = this.ui.stage.getBoundingClientRect()
      if (rect.width === 0) return
      this.playerX = Math.min(Math.max((clientX - rect.left) / rect.width, 0.04), 0.96)
      this.drawPlayer()
    }
    this.ui.stage.addEventListener("mousemove", (e) => aim(e.clientX))
    this.ui.stage.addEventListener(
      "touchmove",
      (e) => {
        if (e.touches[0]) aim(e.touches[0].clientX)
        e.preventDefault()
      },
      { passive: false }
    )
  }

  start(onFinish) {
    this.onFinish = onFinish
    this.score = 0
    this.missed = 0
    this.bullets = []
    this.enemies = []
    this.remaining = SHOOT_SECONDS
    this.running = true

    this.ui.stage.innerHTML = ""
    this.player = document.createElement("div")
    this.player.className = "shooter-player"
    this.player.textContent = "🐿️"
    this.ui.stage.appendChild(this.player)
    this.drawPlayer()
    this.updateLabels()

    this.timerId = setInterval(() => {
      this.remaining--
      this.updateLabels()
      if (this.remaining <= 0) this.stop()
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
    this.ui.statLeft.innerHTML = `スコア: <strong>${this.score}点</strong>`
    this.ui.statRight.innerHTML = `のこり: <strong>${Math.max(this.remaining, 0)}秒</strong>`
  }

  fire() {
    if (!this.running) return
    const rect = this.ui.stage.getBoundingClientRect()
    const el = document.createElement("div")
    el.className = "shooter-bullet"
    el.textContent = "🌰"
    this.ui.stage.appendChild(el)
    const bullet = { el, x: this.playerX * rect.width, y: rect.height - PLAYER_SIZE - 6 }
    el.style.left = `${bullet.x - 8}px`
    el.style.top = `${bullet.y}px`
    this.bullets.push(bullet)
  }

  spawnEnemy() {
    if (!this.running) return
    const rect = this.ui.stage.getBoundingClientRect()
    const kind = ENEMY_KINDS[Math.floor(Math.random() * ENEMY_KINDS.length)]
    const el = document.createElement("div")
    el.className = "shooter-enemy"
    el.textContent = kind.icon
    this.ui.stage.appendChild(el)
    const enemy = { el, kind, x: 16 + Math.random() * Math.max(rect.width - 48, 10), y: -20 }
    el.style.left = `${enemy.x}px`
    el.style.top = `${enemy.y}px`
    this.enemies.push(enemy)
  }

  loop() {
    if (!this.running) return
    const now = performance.now()
    const delta = Math.min((now - this.lastFrame) / 1000, 0.05)
    this.lastFrame = now
    const rect = this.ui.stage.getBoundingClientRect()

    this.bullets = this.bullets.filter((b) => {
      b.y -= BULLET_SPEED * delta
      if (b.y < -20) {
        b.el.remove()
        return false
      }
      b.el.style.top = `${b.y}px`
      return true
    })

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
    const hitB = new Set()
    const hitE = new Set()
    this.enemies.forEach((enemy, ei) => {
      this.bullets.forEach((bullet, bi) => {
        if (hitB.has(bi) || hitE.has(ei)) return
        if (Math.abs(enemy.x - bullet.x) < 24 && Math.abs(enemy.y - bullet.y) < 24) {
          hitB.add(bi)
          hitE.add(ei)
          this.score += enemy.kind.point
          burst(this.ui.stage, enemy.x, enemy.y)
        }
      })
    })
    if (hitE.size === 0) return
    this.bullets = this.bullets.filter((b, i) => (hitB.has(i) ? (b.el.remove(), false) : true))
    this.enemies = this.enemies.filter((e, i) => (hitE.has(i) ? (e.el.remove(), false) : true))
    this.updateLabels()
  }

  stop() {
    this.running = false
    clearInterval(this.timerId)
    clearInterval(this.spawnId)
    clearInterval(this.fireId)
    if (this.frameId) cancelAnimationFrame(this.frameId)
    this.ui.stage.innerHTML = ""
    if (this.onFinish) this.onFinish(this.score, `取り逃がし ${this.missed}匹`)
  }
}

// ============================================================
// 2. バッティング
// ============================================================

const BAT_PITCHES = 10

class BattingGame {
  static title = "⚾ どんぐりバッティング"
  static hint = "飛んでくるどんぐりが白い線に重なったら画面をタップして打ちます。"
  static bestKey = "gameBestBatting"

  constructor(ui) {
    this.ui = ui
    this.ui.stage.addEventListener("click", () => this.swing())
    this.ui.stage.addEventListener(
      "touchstart",
      (e) => {
        e.preventDefault()
        this.swing()
      },
      { passive: false }
    )
  }

  start(onFinish) {
    this.onFinish = onFinish
    this.score = 0
    this.pitch = 0
    this.hits = 0
    this.running = true
    this.ball = null

    this.ui.stage.innerHTML = ""
    this.zone = document.createElement("div")
    this.zone.className = "bat-zone"
    this.ui.stage.appendChild(this.zone)

    this.batter = document.createElement("div")
    this.batter.className = "bat-batter"
    this.batter.textContent = "🐻"
    this.ui.stage.appendChild(this.batter)

    this.updateLabels()
    this.nextPitch()
  }

  updateLabels() {
    this.ui.statLeft.innerHTML = `スコア: <strong>${this.score}点</strong>`
    this.ui.statRight.innerHTML = `${this.pitch} / ${BAT_PITCHES}球`
  }

  nextPitch() {
    if (!this.running) return
    if (this.pitch >= BAT_PITCHES) return this.stop()

    this.pitch++
    this.updateLabels()

    const rect = this.ui.stage.getBoundingClientRect()
    const el = document.createElement("div")
    el.className = "bat-ball"
    el.textContent = "🌰"
    this.ui.stage.appendChild(el)

    // 球ごとに速さを変えてタイミングを取りづらくする
    const speed = 170 + Math.random() * 160
    this.ball = { el, x: rect.width - 20, y: rect.height * 0.45, speed, hit: false }
    el.style.left = `${this.ball.x}px`
    el.style.top = `${this.ball.y}px`

    this.lastFrame = performance.now()
    this.loop()
  }

  loop() {
    if (!this.running || !this.ball) return
    const now = performance.now()
    const delta = Math.min((now - this.lastFrame) / 1000, 0.05)
    this.lastFrame = now

    const b = this.ball
    if (b.hit) {
      // 打ったあとは右上へ飛んでいく
      b.x += 520 * delta
      b.y -= 300 * delta
      b.el.style.left = `${b.x}px`
      b.el.style.top = `${b.y}px`
      const rect = this.ui.stage.getBoundingClientRect()
      if (b.x > rect.width + 40 || b.y < -40) {
        b.el.remove()
        this.ball = null
        setTimeout(() => this.nextPitch(), 250)
        return
      }
    } else {
      b.x -= b.speed * delta
      b.el.style.left = `${b.x}px`
      if (b.x < 6) {
        // 見逃し
        b.el.remove()
        this.ball = null
        setTimeout(() => this.nextPitch(), 250)
        return
      }
    }

    this.frameId = requestAnimationFrame(() => this.loop())
  }

  swing() {
    if (!this.running || !this.ball || this.ball.hit) return
    const zoneLeft = 44
    const zoneRight = 96

    if (this.ball.x >= zoneLeft && this.ball.x <= zoneRight) {
      // 中心に近いほど高得点
      const center = (zoneLeft + zoneRight) / 2
      const accuracy = 1 - Math.abs(this.ball.x - center) / ((zoneRight - zoneLeft) / 2)
      const point = accuracy > 0.6 ? 3 : 1
      this.score += point
      this.hits++
      this.ball.hit = true
      this.ball.el.textContent = point === 3 ? "💥" : "🌰"
      burst(this.ui.stage, this.ball.x, this.ball.y)
      this.updateLabels()
    } else {
      this.batter.classList.add("bat-miss")
      setTimeout(() => this.batter.classList.remove("bat-miss"), 150)
    }
  }

  stop() {
    this.running = false
    if (this.frameId) cancelAnimationFrame(this.frameId)
    this.ui.stage.innerHTML = ""
    if (this.onFinish) this.onFinish(this.score, `${BAT_PITCHES}球中 ${this.hits}本`)
  }
}

// ============================================================
// 3. 落ちもの合わせ
// ============================================================

const DROP_COLS = 6
const DROP_ROWS = 8
const DROP_FRUITS = ["🍎", "🍇", "🍋", "🫐"]
const DROP_SECONDS = 45

class DropGame {
  static title = "🍎 きのみ合わせ"
  static hint = "落としたい列をタップ。同じ実が縦か横に3つ以上つながると消えます。"
  static bestKey = "gameBestDrop"

  constructor(ui) {
    this.ui = ui
  }

  start(onFinish) {
    this.onFinish = onFinish
    this.score = 0
    this.cleared = 0
    this.remaining = DROP_SECONDS
    this.running = true
    this.grid = Array.from({ length: DROP_ROWS }, () => Array(DROP_COLS).fill(null))

    this.ui.stage.innerHTML = ""
    this.board = document.createElement("div")
    this.board.className = "drop-board"
    this.board.style.gridTemplateColumns = `repeat(${DROP_COLS}, 1fr)`
    this.ui.stage.appendChild(this.board)

    this.nextFruit = this.randomFruit()
    this.buildCells()
    this.render()
    this.updateLabels()

    this.timerId = setInterval(() => {
      this.remaining--
      this.updateLabels()
      if (this.remaining <= 0) this.stop()
    }, 1000)
  }

  randomFruit() {
    return DROP_FRUITS[Math.floor(Math.random() * DROP_FRUITS.length)]
  }

  buildCells() {
    this.cells = []
    for (let r = 0; r < DROP_ROWS; r++) {
      for (let c = 0; c < DROP_COLS; c++) {
        const cell = document.createElement("button")
        cell.type = "button"
        cell.className = "drop-cell"
        cell.addEventListener("click", () => this.dropInto(c))
        this.board.appendChild(cell)
        this.cells.push(cell)
      }
    }
  }

  render() {
    for (let r = 0; r < DROP_ROWS; r++) {
      for (let c = 0; c < DROP_COLS; c++) {
        this.cells[r * DROP_COLS + c].textContent = this.grid[r][c] || ""
      }
    }
  }

  updateLabels() {
    this.ui.statLeft.innerHTML = `スコア: <strong>${this.score}点</strong> 次: ${this.nextFruit}`
    this.ui.statRight.innerHTML = `のこり: <strong>${Math.max(this.remaining, 0)}秒</strong>`
  }

  dropInto(col) {
    if (!this.running) return

    // 下から空いている場所を探す
    let row = -1
    for (let r = DROP_ROWS - 1; r >= 0; r--) {
      if (!this.grid[r][col]) {
        row = r
        break
      }
    }
    if (row === -1) return // その列は満杯

    this.grid[row][col] = this.nextFruit
    this.nextFruit = this.randomFruit()
    this.render()
    this.resolveMatches()
    this.updateLabels()

    if (this.isFull()) this.stop()
  }

  isFull() {
    return this.grid[0].every((cell) => cell !== null)
  }

  // 3つ以上つながった実を消し、上の実を落とす。連鎖する限り繰り返す。
  resolveMatches() {
    let chain = 0

    while (true) {
      const marked = this.findMatches()
      if (marked.size === 0) break

      chain++
      marked.forEach((key) => {
        const [r, c] = key.split(",").map(Number)
        this.grid[r][c] = null
      })
      this.cleared += marked.size
      // 連鎖するほど得点が伸びる
      this.score += marked.size * chain
      this.applyGravity()
    }

    if (chain > 0) this.render()
  }

  findMatches() {
    const marked = new Set()

    // 横方向
    for (let r = 0; r < DROP_ROWS; r++) {
      let run = 1
      for (let c = 1; c <= DROP_COLS; c++) {
        const same = c < DROP_COLS && this.grid[r][c] && this.grid[r][c] === this.grid[r][c - 1]
        if (same) {
          run++
        } else {
          if (run >= 3) for (let k = c - run; k < c; k++) marked.add(`${r},${k}`)
          run = 1
        }
      }
    }

    // 縦方向
    for (let c = 0; c < DROP_COLS; c++) {
      let run = 1
      for (let r = 1; r <= DROP_ROWS; r++) {
        const same = r < DROP_ROWS && this.grid[r][c] && this.grid[r][c] === this.grid[r - 1][c]
        if (same) {
          run++
        } else {
          if (run >= 3) for (let k = r - run; k < r; k++) marked.add(`${k},${c}`)
          run = 1
        }
      }
    }

    return marked
  }

  applyGravity() {
    for (let c = 0; c < DROP_COLS; c++) {
      const stack = []
      for (let r = DROP_ROWS - 1; r >= 0; r--) {
        if (this.grid[r][c]) stack.push(this.grid[r][c])
      }
      for (let r = DROP_ROWS - 1; r >= 0; r--) {
        this.grid[r][c] = stack[DROP_ROWS - 1 - r] || null
      }
    }
  }

  stop() {
    this.running = false
    clearInterval(this.timerId)
    this.ui.stage.innerHTML = ""
    if (this.onFinish) this.onFinish(this.score, `${this.cleared}個 消しました`)
  }
}

// ============================================================
// 4. もぐらたたき
// ============================================================

const WHACK_SECONDS = 20
const WHACK_HOLES = 9

class WhackGame {
  static title = "🦔 もぐらたたき"
  static hint = "顔を出した動物をタップ。🐝を叩くと2点マイナスです。"
  static bestKey = "gameBestWhack"

  constructor(ui) {
    this.ui = ui
  }

  start(onFinish) {
    this.onFinish = onFinish
    this.score = 0
    this.hits = 0
    this.remaining = WHACK_SECONDS
    this.running = true

    this.ui.stage.innerHTML = ""
    this.board = document.createElement("div")
    this.board.className = "whack-board"
    this.ui.stage.appendChild(this.board)

    this.holes = []
    for (let i = 0; i < WHACK_HOLES; i++) {
      const hole = document.createElement("button")
      hole.type = "button"
      hole.className = "whack-hole"
      hole.addEventListener("click", () => this.hit(i))
      this.board.appendChild(hole)
      this.holes.push({ el: hole, kind: null })
    }

    this.updateLabels()
    this.timerId = setInterval(() => {
      this.remaining--
      this.updateLabels()
      if (this.remaining <= 0) this.stop()
    }, 1000)
    this.popId = setInterval(() => this.pop(), 620)
  }

  updateLabels() {
    this.ui.statLeft.innerHTML = `スコア: <strong>${this.score}点</strong>`
    this.ui.statRight.innerHTML = `のこり: <strong>${Math.max(this.remaining, 0)}秒</strong>`
  }

  pop() {
    if (!this.running) return
    const empty = this.holes.map((h, i) => (h.kind ? -1 : i)).filter((i) => i >= 0)
    if (empty.length === 0) return

    const index = empty[Math.floor(Math.random() * empty.length)]
    const isBee = Math.random() < 0.25
    const hole = this.holes[index]
    hole.kind = isBee ? "bee" : "mole"
    hole.el.textContent = isBee ? "🐝" : ["🦔", "🐿️", "🐰"][Math.floor(Math.random() * 3)]
    hole.el.classList.add("whack-up")

    setTimeout(() => {
      if (hole.kind) this.clearHole(hole)
    }, 900)
  }

  clearHole(hole) {
    hole.kind = null
    hole.el.textContent = ""
    hole.el.classList.remove("whack-up")
  }

  hit(index) {
    if (!this.running) return
    const hole = this.holes[index]
    if (!hole.kind) return

    if (hole.kind === "bee") {
      this.score = Math.max(this.score - 2, 0)
    } else {
      this.score++
      this.hits++
    }
    this.clearHole(hole)
    this.updateLabels()
  }

  stop() {
    this.running = false
    clearInterval(this.timerId)
    clearInterval(this.popId)
    this.ui.stage.innerHTML = ""
    if (this.onFinish) this.onFinish(this.score, `${this.hits}匹 たたきました`)
  }
}

// ============================================================
// 5〜7. スポーツ系(左右に動くゲージを止めて狙う)
// ============================================================

const AIM_TRIES = 10

// バスケ・サッカー・ホッケーは「動く狙いを止める」共通の遊び方。
// 設定だけ差し替えて3種類にしている。
class AimGameBase {
  constructor(ui) {
    this.ui = ui
    this.ui.stage.addEventListener("click", () => this.shoot())
    this.ui.stage.addEventListener(
      "touchstart",
      (e) => {
        e.preventDefault()
        this.shoot()
      },
      { passive: false }
    )
  }

  config() {
    return this.constructor.config
  }

  start(onFinish) {
    this.onFinish = onFinish
    this.score = 0
    this.tries = 0
    this.goals = 0
    this.running = true
    this.markerX = 0
    this.direction = 1

    const cfg = this.config()
    this.ui.stage.innerHTML = ""
    this.ui.stage.classList.add("aim-stage")
    this.ui.stage.style.setProperty("--aim-bg", cfg.background)

    this.field = document.createElement("div")
    this.field.className = "aim-field"
    this.field.innerHTML = `
      <div class="aim-goal">${cfg.goal}</div>
      <div class="aim-target-zone"></div>
      <div class="aim-bar"><div class="aim-marker">${cfg.ball}</div></div>
      <div class="aim-player">${cfg.player}</div>
    `
    this.ui.stage.appendChild(this.field)

    this.marker = this.field.querySelector(".aim-marker")
    this.zone = this.field.querySelector(".aim-target-zone")

    this.updateLabels()
    this.lastFrame = performance.now()
    this.loop()
  }

  updateLabels() {
    const cfg = this.config()
    this.ui.statLeft.innerHTML = `スコア: <strong>${this.score}点</strong>`
    this.ui.statRight.innerHTML = `${this.tries} / ${AIM_TRIES}${cfg.unit}`
  }

  loop() {
    if (!this.running) return
    const now = performance.now()
    const delta = Math.min((now - this.lastFrame) / 1000, 0.05)
    this.lastFrame = now

    // 回数が進むほど速くなる
    const speed = this.config().speed + this.tries * 6
    this.markerX += this.direction * speed * delta
    if (this.markerX >= 100) {
      this.markerX = 100
      this.direction = -1
    } else if (this.markerX <= 0) {
      this.markerX = 0
      this.direction = 1
    }
    this.marker.style.left = `${this.markerX}%`

    this.frameId = requestAnimationFrame(() => this.loop())
  }

  shoot() {
    if (!this.running || this.locked) return

    this.tries++
    // 中央(50%)に近いほど高得点
    const diff = Math.abs(this.markerX - 50)
    let point = 0
    let label = "ミス"

    if (diff <= 6) {
      point = 3
      label = this.config().perfect
    } else if (diff <= 16) {
      point = 1
      label = this.config().good
    }

    this.score += point
    if (point > 0) {
      this.goals++
      this.zone.classList.add("aim-flash")
      setTimeout(() => this.zone.classList.remove("aim-flash"), 200)
    }

    this.ui.result.textContent = label
    this.updateLabels()

    if (this.tries >= AIM_TRIES) {
      this.locked = true
      setTimeout(() => this.stop(), 400)
    }
  }

  stop() {
    this.running = false
    this.locked = false
    if (this.frameId) cancelAnimationFrame(this.frameId)
    this.ui.stage.classList.remove("aim-stage")
    this.ui.stage.innerHTML = ""
    if (this.onFinish) this.onFinish(this.score, `${AIM_TRIES}本中 ${this.goals}本成功`)
  }
}

class BasketGame extends AimGameBase {
  static title = "🏀 バスケシュート"
  static hint = "左右に動くボールが中央に来たらタップ。真ん中ほど高得点です。"
  static bestKey = "gameBestBasket"
  static config = {
    ball: "🏀",
    goal: "🥅",
    player: "🐻",
    background: "linear-gradient(180deg, #ffe0b2 0%, #ffcc80 100%)",
    speed: 95,
    unit: "本",
    perfect: "スリーポイント！",
    good: "ゴール！"
  }
}

class SoccerGame extends AimGameBase {
  static title = "⚽ サッカーPK"
  static hint = "左右に動くボールが中央に来たらタップ。真ん中ほど高得点です。"
  static bestKey = "gameBestSoccer"
  static config = {
    ball: "⚽",
    goal: "🥅",
    player: "🦊",
    background: "linear-gradient(180deg, #c8e6c9 0%, #a5d6a7 100%)",
    speed: 110,
    unit: "本",
    perfect: "ゴール左上ギリギリ！",
    good: "ゴール！"
  }
}

class HockeyGame extends AimGameBase {
  static title = "🏒 アイスホッケー"
  static hint = "左右に動くパックが中央に来たらタップ。真ん中ほど高得点です。"
  static bestKey = "gameBestHockey"
  static config = {
    ball: "🏒",
    goal: "🥅",
    player: "🐧",
    background: "linear-gradient(180deg, #e1f5fe 0%, #b3e5fc 100%)",
    speed: 130,
    unit: "本",
    perfect: "ハットトリック級！",
    good: "ゴール！"
  }
}

// ============================================================
// 共通処理
// ============================================================

const GAMES = [
  ShootingGame,
  BattingGame,
  DropGame,
  WhackGame,
  BasketGame,
  SoccerGame,
  HockeyGame
]

function burst(stage, x, y) {
  const el = document.createElement("div")
  el.className = "shooter-burst"
  el.textContent = "✨"
  el.style.left = `${x - 10}px`
  el.style.top = `${y}px`
  stage.appendChild(el)
  setTimeout(() => el.remove(), 320)
}

class MiniGameHost {
  constructor(root) {
    this.root = root
    this.startButton = root.querySelector("#game-start")
    this.shuffleButton = root.querySelector("#game-shuffle")
    this.panel = root.querySelector("#game-panel")
    this.bestLabel = root.querySelector("#game-best")
    this.resultLabel = root.querySelector("#game-result")
    this.hintLabel = root.querySelector("#game-hint")

    this.ui = {
      stage: root.querySelector("#game-stage"),
      statLeft: root.querySelector("#game-stat-left"),
      statRight: root.querySelector("#game-stat-right"),
      result: this.resultLabel
    }

    this.startButton.addEventListener("click", () => this.play())
    this.shuffleButton.addEventListener("click", () => this.pickRandom())

    this.pickRandom()
  }

  pickRandom() {
    if (this.playing) return
    const others = GAMES.filter((g) => g !== this.GameClass)
    const pool = others.length > 0 ? others : GAMES
    this.GameClass = pool[Math.floor(Math.random() * pool.length)]
    this.game = new this.GameClass(this.ui)

    this.startButton.textContent = this.GameClass.title
    this.hintLabel.textContent = this.GameClass.hint
    this.resultLabel.textContent = ""
    this.showBest()
  }

  best() {
    return Number(localStorage.getItem(this.GameClass.bestKey) || 0)
  }

  showBest() {
    const best = this.best()
    this.bestLabel.textContent = best > 0 ? `このゲームの最高: ${best}点` : ""
  }

  play() {
    if (this.playing) return
    this.playing = true

    this.panel.classList.remove("d-none")
    this.resultLabel.textContent = ""
    this.startButton.textContent = "プレイ中…"
    this.startButton.disabled = true
    this.shuffleButton.disabled = true

    this.game.start((score, detail) => this.finish(score, detail))
  }

  finish(score, detail) {
    this.playing = false

    const best = this.best()
    if (score > best) {
      localStorage.setItem(this.GameClass.bestKey, String(score))
      this.resultLabel.textContent = `${score}点！自己ベスト更新です`
    } else {
      this.resultLabel.textContent = `${score}点(${detail})`
    }

    this.showBest()
    this.startButton.textContent = "もう一度あそぶ"
    this.startButton.disabled = false
    this.shuffleButton.disabled = false
  }
}

function initMiniGame() {
  const root = document.querySelector("#mini-game")
  if (root) new MiniGameHost(root)
}

document.addEventListener("DOMContentLoaded", initMiniGame)
document.addEventListener("turbo:load", initMiniGame)
