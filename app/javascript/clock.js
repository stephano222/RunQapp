// ナビバーの時計。1秒ごとに現在時刻を書き換える。
// サーバーの時刻を埋め込むと表示した瞬間から古くなるので、ブラウザ側で動かす。

const WEEKDAYS = ["日", "月", "火", "水", "木", "金", "土"]

function pad(value) {
  return String(value).padStart(2, "0")
}

function renderClock(element) {
  const now = new Date()
  const date = `${now.getMonth() + 1}/${now.getDate()}(${WEEKDAYS[now.getDay()]})`
  const time = `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`
  element.textContent = `${date} ${time}`
}

let clockTimer = null

function initClock() {
  const element = document.querySelector("#navbar-clock")
  if (clockTimer) clearInterval(clockTimer)
  if (!element) return

  renderClock(element)
  clockTimer = setInterval(() => renderClock(element), 1000)
}

document.addEventListener("DOMContentLoaded", initClock)
document.addEventListener("turbo:load", initClock)
