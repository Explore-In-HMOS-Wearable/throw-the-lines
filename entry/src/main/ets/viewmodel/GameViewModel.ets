import { PinData }                   from '../model/LevelConfig'
import { ScreenState }               from '../model/ScreenState'
import { DrawService, DrawSnapshot } from '../service/DrawService'
import { LevelService }              from '../service/LevelService'

const STORAGE_KEY = 'aaw_last_level'

@Observed
export class GameViewModel {
  screenState: ScreenState  = ScreenState.START
  pins: PinData[]           = []
  wheelAngle: number        = 0
  currentLevel: number      = 1
  savedLevel: number        = 1
  pinQueue: number[]        = []
  pinFlying: boolean        = false
  pinY: number              = 0
  pinsPlaced: number        = 0
  showRayBurst: boolean     = false
  rayBurstProgress: number  = 0

  cw: number = 360
  ch: number = 740
  cx: number = 180
  cy: number = 300

  readonly wheelR:        number = 48
  readonly PIN_LENGTH:    number = 38
  readonly BALL_R:        number = 10
  readonly BALL_R_MIN:    number = 4
  readonly PIN_SPEED:     number = 11
  readonly SHOOTER_Y_OFF: number = 28

  levelBallR: number = 10

  readonly drawService: DrawService     = new DrawService()
  private readonly levels: LevelService = new LevelService()
  private intervalId: number = -1
  private transitionTimeoutId: number = -1

  initCanvas(width: number, height: number): void {
    const size = Math.min(width, height)
    const r    = size * 0.5

    this.cw   = size
    this.ch   = size
    this.cx   = size * 0.5
    this.cy   = size * 0.42
    this.pinY = (size * 0.5 + r * 0.72) - this.SHOOTER_Y_OFF - this.PIN_LENGTH
  }

  onTap(): void {
    if (this.screenState === ScreenState.START) {
      return
    }
    if (this.screenState === ScreenState.FAILED) {
      this.startLevel(this.currentLevel)
      return
    }
    if (this.screenState === ScreenState.PASSED) {
      this.clearTransitionTimeout()
      this.startLevel(this.currentLevel + 1)
      return
    }
    if (this.screenState !== ScreenState.GAME) {
      return
    }
    if (!this.pinFlying && this.pinQueue.length > 0) {
      this.pinFlying = true
      this.pinY      = this.ch - this.SHOOTER_Y_OFF - this.PIN_LENGTH
    }
  }

  onTapContinue(): void {
    this.startLevel(this.savedLevel)
  }

  onTapNewGame(): void {
    this.startLevel(1)
  }

  startLevel(levelNum: number): void {
    clearInterval(this.intervalId)
    this.clearTransitionTimeout()
    const lvl             = this.levels.getLevel(levelNum)
    this.currentLevel     = levelNum
    this.screenState      = ScreenState.GAME
    this.pins             = []
    this.wheelAngle       = 0
    this.pinFlying        = false
    this.pinsPlaced       = 0
    this.showRayBurst     = false
    this.rayBurstProgress = 0
    this.pinY             = this.ch - this.SHOOTER_Y_OFF - this.PIN_LENGTH

    AppStorage.setOrCreate<number>(STORAGE_KEY, levelNum)

    this.levelBallR = this.calcBallR(lvl.totalPins)
    console.info(`[TlWatch] startLevel: level=${levelNum} totalPins=${lvl.totalPins} ballR=${this.levelBallR} speed=${lvl.rotSpeed}`)

    for (let i = 0; i < lvl.prePlacedAngles.length; i++) {
      this.pins.push({ angle: lvl.prePlacedAngles[i], num: -(i + 1), prePlaced: true })
    }

    this.pinQueue = []
    for (let i = 1; i <= lvl.totalPins; i++) {
      this.pinQueue.push(i)
    }

    this.intervalId = setInterval(() => {
      this.update()
    }, 16)
  }

  stopAll(): void {
    clearInterval(this.intervalId)
    this.clearTransitionTimeout()
  }

  toDrawSnapshot(): DrawSnapshot {
    const s = new DrawSnapshot()
    s.cw               = this.cw
    s.ch               = this.ch
    s.cx               = this.cx
    s.cy               = this.cy
    s.wheelR           = this.wheelR
    s.wheelAngle       = this.wheelAngle
    s.pins             = this.pins
    s.pinLength        = this.PIN_LENGTH
    s.ballR            = this.levelBallR
    s.currentLevel     = this.currentLevel
    s.savedLevel       = this.savedLevel
    s.pinFlying        = this.pinFlying
    s.pinY             = this.pinY
    s.pinQueue         = this.pinQueue
    s.shooterYOff      = this.SHOOTER_Y_OFF
    s.screenState      = this.screenState
    s.showRayBurst     = this.showRayBurst
    s.rayBurstProgress = this.rayBurstProgress
    return s
  }

  private update(): void {
    this.wheelAngle += 0.028

    if (this.showRayBurst) {
      this.rayBurstProgress += 0.035
      if (this.rayBurstProgress >= 1.2) {
        clearInterval(this.intervalId)
        this.screenState = ScreenState.PASSED
        this.scheduleNextLevelTransition()
      }
      return
    }

    if (!this.pinFlying) {
      return
    }

    this.pinY -= this.PIN_SPEED

    if (this.pinY <= this.cy + this.wheelR) {
      const lvl    = this.levels.getLevel(this.currentLevel)
      let relAngle = (Math.PI - this.wheelAngle) % (Math.PI * 2)
      if (relAngle < 0) {
        relAngle += Math.PI * 2
      }

      if (this.checkCollision(relAngle, lvl.minDiff)) {
        this.triggerFailed()
        return
      }

      const pinNum = this.pinQueue.shift()!
      this.pins.push({ angle: relAngle, num: pinNum, prePlaced: false })
      this.pinsPlaced++
      this.pinFlying = false
      this.pinY      = this.ch - this.SHOOTER_Y_OFF - this.PIN_LENGTH

      if (this.pinsPlaced >= lvl.totalPins) {
        this.triggerPassed()
      }
    }
  }

  private checkCollision(newAngle: number, minDiff: number): boolean {
    for (const p of this.pins) {
      let diff = Math.abs(newAngle - p.angle)
      if (diff > Math.PI) {
        diff = Math.PI * 2 - diff
      }
      if (diff < minDiff) {
        return true
      }
    }
    return false
  }

  private triggerFailed(): void {
    console.info(`[TlWatch] triggerFailed: level=${this.currentLevel} pinsPlaced=${this.pinsPlaced}`)
    clearInterval(this.intervalId)
    this.pinFlying = false
    this.clearTransitionTimeout()
    this.transitionTimeoutId = setTimeout(() => {
      this.transitionTimeoutId = -1
      this.screenState = ScreenState.FAILED
    }, 400)
  }

  private triggerPassed(): void {
    console.info(`[TlWatch] triggerPassed: level=${this.currentLevel} pinsPlaced=${this.pinsPlaced}`)
    this.pinFlying        = false
    this.showRayBurst     = true
    this.rayBurstProgress = 0
  }

  private scheduleNextLevelTransition(): void {
    this.clearTransitionTimeout()
    this.transitionTimeoutId = setTimeout(() => {
      this.transitionTimeoutId = -1
      if (this.screenState === ScreenState.PASSED) {
        this.startLevel(this.currentLevel + 1)
      }
    }, 900)
  }

  private clearTransitionTimeout(): void {
    if (this.transitionTimeoutId !== -1) {
      clearTimeout(this.transitionTimeoutId)
      this.transitionTimeoutId = -1
    }
  }

  private calcBallR(totalPins: number): number {
    const t = Math.min(Math.max((totalPins - 3) / 49, 0), 1)
    return Math.round((this.BALL_R - (this.BALL_R - this.BALL_R_MIN) * t) * 10) / 10
  }
}
