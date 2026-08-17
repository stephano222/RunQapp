import "@hotwired/turbo-rails"

// Bootstrapは全体を読み込むとPopperごと入って200KB近くになる。
// 実際に使っているのは折りたたみメニューと通知の閉じるボタンだけなので、
// その2つだけを読み込む。
import "bootstrap/js/dist/collapse"
import "bootstrap/js/dist/alert"
import "./typing_practice"
import "./clock"
import "./shakyo"
import "./practice_memo"
import "./bgm"
