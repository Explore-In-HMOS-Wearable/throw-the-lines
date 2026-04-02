import { GameViewModel } from '../viewmodel/GameViewModel'
import { DrawSnapshot, DrawService } from '../service/DrawService'
import { ScreenState }   from '../model/ScreenState'
import { ConstantUI } from '../util/ConstantUI'

@Entry
@Component
struct Index {
  private vm: GameViewModel = new GameViewModel()
  private ctx: CanvasRenderingContext2D | null = null
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private loopId: number = -1

  build() {
    Stack() {
      Canvas(this.canvasCtx)
        .width(ConstantUI.FULL_WIDTH)
        .height(ConstantUI.FULL_HEIGHT)
        .onReady(() => {
          this.ctx = this.canvasCtx
          const size = Math.min(this.ctx.width, this.ctx.height)
          this.vm.initCanvas(size, size)
          this.startRenderLoop()
        })
        .onClick((event: ClickEvent) => {
          this.handleClick(event.x, event.y)
        })
    }
    .width(ConstantUI.FULL_WIDTH)
    .height(ConstantUI.FULL_HEIGHT)
    .backgroundColor($r('app.color.canvas_background_color'))
  }

  private handleClick(x: number, y: number): void {
    if (this.vm.screenState === ScreenState.START) {
      const cx  = this.vm.cx
      const ch  = this.vm.ch
      const newGameY  = ch * 0.68
      const continueY = ch * 0.68 + 60

      if (Math.abs(x - cx) <= 80 && Math.abs(y - newGameY) <= 22) {
        this.vm.onTapNewGame()
        return
      }

      if (this.vm.savedLevel > 1 && Math.abs(x - cx) <= 80 && Math.abs(y - continueY) <= 22) {
        this.vm.onTapContinue()
        return
      }
      return
    }

    this.vm.onTap()
  }

  private startRenderLoop(): void {
    this.loopId = setInterval(() => {
      this.redraw()
    }, 16)
  }

  aboutToDisappear(): void {
    clearInterval(this.loopId)
    this.vm.stopAll()
  }
  private redraw(): void {
    if (this.ctx === null) { return }
    const s: DrawSnapshot = this.vm.toDrawSnapshot()
    this.vm.drawService.draw(this.ctx, s)
  }
}