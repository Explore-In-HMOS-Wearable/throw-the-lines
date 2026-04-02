import { ScreenState } from '../model/ScreenState'
import { PinData }     from '../model/LevelConfig'

export class DrawSnapshot {
  cw: number               = 0
  ch: number               = 0
  cx: number               = 0
  cy: number               = 0
  wheelR: number           = 0
  wheelAngle: number       = 0
  pins: PinData[]          = []
  pinLength: number        = 0
  ballR: number            = 0
  currentLevel: number     = 1
  savedLevel: number       = 1
  pinFlying: boolean       = false
  pinY: number             = 0
  pinQueue: number[]       = []
  shooterYOff: number      = 28
  screenState: ScreenState = ScreenState.START
  showRayBurst: boolean    = false
  rayBurstProgress: number = 0
}

export class DrawService {
  onDispose?(): void {}

  private readonly BG        = '#F2EDE4'
  private readonly BG_FAILED = '#E74C3C'
  private readonly BG_PASSED = '#27AE60'
  private readonly DARK      = '#1A1A1A'
  private readonly WHITE     = '#FFFFFF'

  draw(ctx: CanvasRenderingContext2D, s: DrawSnapshot): void {
    ctx.clearRect(0, 0, s.cw, s.ch)

    if (s.screenState === ScreenState.START) {
      this.drawStartScreen(ctx, s)
      return
    }

    if (s.screenState === ScreenState.FAILED) {
      this.drawFailedScreen(ctx, s)
      return
    }

    if (s.screenState === ScreenState.PASSED) {
      this.drawPassedScreen(ctx, s)
      return
    }

    const bgCol = s.showRayBurst
      ? this.lerpColor(this.BG, this.BG_PASSED, Math.min(s.rayBurstProgress, 1))
      : this.BG

    ctx.fillStyle = bgCol
    ctx.fillRect(0, 0, s.cw, s.ch)

    if (s.showRayBurst && s.rayBurstProgress > 0.1) {
      this.drawRayBurst(ctx, s.cx, s.cy, s.wheelR, s.rayBurstProgress, s.ch)
    }

    this.drawWheel(ctx, s.cx, s.cy, s.wheelR, s.currentLevel)
    this.drawPins(ctx, s.cx, s.cy, s.wheelR, s.wheelAngle, s.pins, s.pinLength, s.ballR)

    if (s.pinFlying) {
      this.drawFlyingPin(ctx, s.cx, s.pinY, s.pinQueue, s.pinLength, s.ballR)
    } else {
      this.drawQueue(ctx, s.cx, s.ch, s.pinQueue, s.pinLength, s.ballR, s.shooterYOff)
    }
  }

  private drawStartScreen(ctx: CanvasRenderingContext2D, s: DrawSnapshot): void {
    ctx.fillStyle = this.BG
    ctx.fillRect(0, 0, s.cw, s.ch)

    this.drawDecorativeWheel(ctx, s.cx, s.ch * 0.22, s.cw * 0.1)

    ctx.fillStyle = this.DARK
    ctx.font = 'bold 52px sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText('TL', s.cx, s.ch * 0.40)

    ctx.fillStyle = `rgba(26,26,26,0.45)`
    ctx.font = 'bold 11px sans-serif'
    ctx.fillText('PLACE ALL PINS', s.cx, s.ch * 0.49)

    ctx.fillStyle = `rgba(26,26,26,0.25)`
    ctx.fillRect(s.cx - 36, s.ch * 0.535, 72, 1)

    ctx.fillStyle = `rgba(26,26,26,0.35)`
    ctx.font = '10px sans-serif'
    ctx.fillText('50 LEVELS', s.cx, s.ch * 0.565)

    this.drawButton(ctx, s.cx, s.ch * 0.68, 'NEW GAME')

    if (s.savedLevel > 1) {
      this.drawButton(ctx, s.cx, s.ch * 0.68 + 60, `CONTINUE  ${s.savedLevel}`)
    }
  }

  private drawDecorativeWheel(ctx: CanvasRenderingContext2D, cx: number, cy: number, r: number): void {
    ctx.beginPath()
    ctx.arc(cx, cy, r, 0, Math.PI * 2)
    ctx.strokeStyle = `rgba(26,26,26,0.35)`
    ctx.lineWidth = 1.5
    ctx.stroke()

    ctx.beginPath()
    ctx.arc(cx, cy, 3, 0, Math.PI * 2)
    ctx.fillStyle = `rgba(26,26,26,0.35)`
    ctx.fill()

    const pinLen = r * 0.55
    for (let i = 0; i < 8; i++) {
      const a  = (i / 8) * Math.PI * 2
      const x1 = cx + Math.cos(a) * r
      const y1 = cy + Math.sin(a) * r
      const x2 = cx + Math.cos(a) * (r + pinLen)
      const y2 = cy + Math.sin(a) * (r + pinLen)
      ctx.beginPath()
      ctx.moveTo(x1, y1)
      ctx.lineTo(x2, y2)
      ctx.strokeStyle = `rgba(26,26,26,0.35)`
      ctx.lineWidth = 1.5
      ctx.lineCap = 'round'
      ctx.stroke()
      ctx.beginPath()
      ctx.arc(x2, y2, 2, 0, Math.PI * 2)
      ctx.fillStyle = `rgba(26,26,26,0.35)`
      ctx.fill()
    }
  }

  private drawButton(ctx: CanvasRenderingContext2D, x: number, y: number, label: string): void {
    const w = 160
    const h = 44
    const r = 22
    const left   = x - w / 2
    const top    = y - h / 2
    const right  = x + w / 2
    const bottom = y + h / 2

    ctx.beginPath()
    ctx.moveTo(left + r, top)
    ctx.lineTo(right - r, top)
    ctx.arcTo(right, top, right, top + r, r)
    ctx.lineTo(right, bottom - r)
    ctx.arcTo(right, bottom, right - r, bottom, r)
    ctx.lineTo(left + r, bottom)
    ctx.arcTo(left, bottom, left, bottom - r, r)
    ctx.lineTo(left, top + r)
    ctx.arcTo(left, top, left + r, top, r)
    ctx.closePath()
    ctx.fillStyle = this.DARK
    ctx.fill()

    ctx.fillStyle = this.WHITE
    ctx.font = 'bold 14px sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText(label, x, y)
  }

  private drawFailedScreen(ctx: CanvasRenderingContext2D, s: DrawSnapshot): void {
    ctx.fillStyle = this.BG_FAILED
    ctx.fillRect(0, 0, s.cw, s.ch)

    this.drawWheel(ctx, s.cx, s.cy, s.wheelR, s.currentLevel)
    this.drawPins(ctx, s.cx, s.cy, s.wheelR, s.wheelAngle, s.pins, s.pinLength, s.ballR)

    ctx.fillStyle = this.WHITE
    ctx.font = 'bold 36px sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText('FAILED', s.cx, s.ch * 0.72)

    ctx.font = 'bold 20px sans-serif'
    ctx.fillText(`Level ${s.currentLevel}`, s.cx, s.ch * 0.72 + 48)
  }

  private drawPassedScreen(ctx: CanvasRenderingContext2D, s: DrawSnapshot): void {
    ctx.fillStyle = this.BG_PASSED
    ctx.fillRect(0, 0, s.cw, s.ch)

    this.drawWheel(ctx, s.cx, s.cy, s.wheelR, s.currentLevel)
    this.drawPins(ctx, s.cx, s.cy, s.wheelR, s.wheelAngle, s.pins, s.pinLength, s.ballR)

    ctx.fillStyle = this.WHITE
    ctx.font = 'bold 36px sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText('PASSED', s.cx, s.ch * 0.72)

    ctx.font = 'bold 20px sans-serif'
    ctx.fillText(`Level ${s.currentLevel}`, s.cx, s.ch * 0.72 + 48)
  }

  private drawRayBurst(
    ctx: CanvasRenderingContext2D,
    cx: number, cy: number, wheelR: number,
    rayBurstProgress: number, ch: number,
  ): void {
    const p      = Math.min(rayBurstProgress, 1)
    const rayLen = p * (ch * 0.7)
    ctx.save()
    ctx.globalAlpha = (1 - p) * 0.35
    for (let i = 0; i < 16; i++) {
      const angle = (i / 16) * Math.PI * 2
      ctx.beginPath()
      ctx.moveTo(cx + Math.cos(angle) * wheelR, cy + Math.sin(angle) * wheelR)
      ctx.lineTo(cx + Math.cos(angle) * (wheelR + rayLen), cy + Math.sin(angle) * (wheelR + rayLen))
      ctx.strokeStyle = this.WHITE
      ctx.lineWidth   = 2
      ctx.stroke()
    }
    ctx.globalAlpha = 1
    ctx.restore()
  }

  private drawWheel(
    ctx: CanvasRenderingContext2D,
    cx: number, cy: number, wheelR: number,
    currentLevel: number,
  ): void {
    ctx.beginPath()
    ctx.arc(cx, cy, wheelR, 0, Math.PI * 2)
    ctx.fillStyle = this.DARK
    ctx.fill()

    ctx.fillStyle = this.WHITE
    ctx.font = `bold ${currentLevel >= 10 ? 22 : 26}px sans-serif`
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText(`${currentLevel}`, cx, cy)
  }

  private drawPins(
    ctx: CanvasRenderingContext2D,
    cx: number, cy: number, wheelR: number,
    wheelAngle: number,
    pins: PinData[],
    pinLength: number, ballR: number,
  ): void {
    for (const pin of pins) {
      const a     = wheelAngle + pin.angle
      const sinA  = Math.sin(a)
      const cosA  = Math.cos(a)
      const rimX  = cx + wheelR * sinA
      const rimY  = cy - wheelR * cosA
      const ballX = cx + (wheelR + pinLength) * sinA
      const ballY = cy - (wheelR + pinLength) * cosA

      ctx.beginPath()
      ctx.moveTo(rimX, rimY)
      ctx.lineTo(ballX, ballY)
      ctx.strokeStyle = pin.prePlaced ? 'rgba(26,26,26,0.45)' : this.DARK
      ctx.lineWidth   = pin.prePlaced ? 1.5 : 2.2
      ctx.lineCap     = 'round'
      ctx.stroke()

      ctx.beginPath()
      ctx.arc(ballX, ballY, ballR, 0, Math.PI * 2)
      ctx.fillStyle = pin.prePlaced ? 'rgba(26,26,26,0.55)' : this.DARK
      ctx.fill()

      if (!pin.prePlaced) {
        ctx.fillStyle = this.WHITE
        ctx.font = 'bold 8px sans-serif'
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        ctx.fillText(`${pin.num}`, ballX, ballY)
      }
    }
  }

  private drawFlyingPin(
    ctx: CanvasRenderingContext2D,
    cx: number, pinY: number,
    pinQueue: number[],
    pinLength: number, ballR: number,
  ): void {
    ctx.beginPath()
    ctx.moveTo(cx, pinY)
    ctx.lineTo(cx, pinY + pinLength)
    ctx.strokeStyle = this.DARK
    ctx.lineWidth   = 2.2
    ctx.lineCap     = 'round'
    ctx.stroke()

    ctx.beginPath()
    ctx.arc(cx, pinY + pinLength, ballR, 0, Math.PI * 2)
    ctx.fillStyle = this.DARK
    ctx.fill()

    ctx.fillStyle = this.WHITE
    ctx.font = 'bold 8px sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText(`${pinQueue[0] ?? ''}`, cx, pinY + pinLength)
  }

  private drawQueue(
    ctx: CanvasRenderingContext2D,
    cx: number, ch: number,
    pinQueue: number[],
    pinLength: number, ballR: number,
    shooterYOff: number,
  ): void {
    if (pinQueue.length === 0) {
      return
    }

    const shooterY = ch - shooterYOff

    ctx.beginPath()
    ctx.moveTo(cx, shooterY - pinLength)
    ctx.lineTo(cx, shooterY)
    ctx.strokeStyle = this.DARK
    ctx.lineWidth   = 2.2
    ctx.lineCap     = 'round'
    ctx.stroke()

    ctx.beginPath()
    ctx.arc(cx, shooterY, ballR, 0, Math.PI * 2)
    ctx.fillStyle = this.DARK
    ctx.fill()

    ctx.fillStyle = this.WHITE
    ctx.font = 'bold 8px sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText(`${pinQueue[0]}`, cx, shooterY)

    const maxShow = Math.min(pinQueue.length - 1, 4)
    for (let i = 1; i <= maxShow; i++) {
      const opacity = 1 - i * 0.18
      const scale   = 1 - i * 0.1
      const qBallR  = ballR * scale
      const qY      = shooterY + i * (ballR * 2.4 + 4)

      ctx.beginPath()
      ctx.arc(cx, qY, qBallR, 0, Math.PI * 2)
      ctx.fillStyle = `rgba(26,26,26,${opacity})`
      ctx.fill()

      ctx.fillStyle = `rgba(255,255,255,${opacity})`
      ctx.font = `bold ${Math.round(8 * scale)}px sans-serif`
      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'
      ctx.fillText(`${pinQueue[i]}`, cx, qY)
    }
  }

  private lerpColor(a: string, b: string, t: number): string {
    const ah = a.replace('#', '')
    const bh = b.replace('#', '')
    const ar = parseInt(ah.substring(0, 2), 16)
    const ag = parseInt(ah.substring(2, 4), 16)
    const ab = parseInt(ah.substring(4, 6), 16)
    const br = parseInt(bh.substring(0, 2), 16)
    const bg = parseInt(bh.substring(2, 4), 16)
    const bb = parseInt(bh.substring(4, 6), 16)
    return `rgb(${Math.round(ar + (br - ar) * t)},${Math.round(ag + (bg - ag) * t)},${Math.round(ab + (bb - ab) * t)})`
  }
}