// 練習画面のメモ欄。
// 自分で追加したコードはサーバーに保存でき、公式コードでも
// ブラウザに残るようにして、どちらでも書き留められるようにしている。

class PracticeMemo {
  constructor(root) {
    this.root = root
    this.snippetId = root.dataset.snippetId
    this.textarea = root.querySelector("#memo-text")
    this.status = root.querySelector("#memo-status")
    this.saveButton = root.querySelector("#memo-save")
    this.clearButton = root.querySelector("#memo-clear")

    this.storageKey = `practiceMemo:${this.snippetId}`

    this.restoreLocal()
    this.bind()
  }

  // サーバーに保存されたメモが無い場合だけ、この端末の下書きを復元する
  restoreLocal() {
    if (this.textarea.value.trim() !== "") return

    const saved = localStorage.getItem(this.storageKey)
    if (saved) {
      this.textarea.value = saved
      this.showStatus("この端末に保存された内容です")
    }
  }

  bind() {
    // 打ちながら書けるよう、入力のたびに端末側へ控えておく
    this.textarea.addEventListener("input", () => {
      localStorage.setItem(this.storageKey, this.textarea.value)
      this.showStatus("下書きを保存しました")
    })

    if (this.saveButton) {
      this.saveButton.addEventListener("click", () => this.save())
    }

    this.clearButton.addEventListener("click", () => this.clear())
  }

  async save() {
    this.saveButton.disabled = true
    this.showStatus("保存中…")

    const token = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(`/snippets/${this.snippetId}/memo`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify({ memo: this.textarea.value })
      })

      if (response.ok) {
        localStorage.removeItem(this.storageKey)
        this.showStatus("保存しました")
      } else {
        this.showStatus("保存できませんでした")
      }
    } catch {
      this.showStatus("通信に失敗しました")
    } finally {
      this.saveButton.disabled = false
    }
  }

  clear() {
    this.textarea.value = ""
    localStorage.removeItem(this.storageKey)
    this.showStatus("消しました")
    this.textarea.focus()
  }

  showStatus(message) {
    this.status.textContent = message
    clearTimeout(this.statusTimer)
    this.statusTimer = setTimeout(() => {
      this.status.textContent = ""
    }, 2500)
  }
}

function initPracticeMemo() {
  const root = document.querySelector("#practice-memo")
  if (root) new PracticeMemo(root)
}

document.addEventListener("DOMContentLoaded", initPracticeMemo)
document.addEventListener("turbo:load", initPracticeMemo)
