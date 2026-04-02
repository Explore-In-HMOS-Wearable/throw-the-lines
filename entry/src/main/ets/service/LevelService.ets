import { LevelConfig } from '../model/LevelConfig'

export class LevelService {
  onDispose?(): void {}

  private readonly levels: LevelConfig[]

  constructor() {
    this.levels = this.buildLevels()
  }

  getLevel(levelNum: number): LevelConfig {
    return this.levels[Math.min(levelNum - 1, this.levels.length - 1)]
  }

  private buildLevels(): LevelConfig[] {
    const levels: LevelConfig[] = []
    for (let i = 1; i <= 50; i++) {
      const totalPins        = 3 + (i - 1)
      const prePlacedCount   = i <= 3 ? 0 : Math.floor((i - 1) / 4)
      const prePlacedAngles: number[] = []
      for (let p = 0; p < prePlacedCount; p++) {
        prePlacedAngles.push((p * Math.PI * 2) / (prePlacedCount * 2 + 2))
      }
      levels.push({
        levelNum:          i,
        totalPins,
        prePlacedAngles,
        rotSpeed:          0.028 + i * 0.0015,
        directionChange:   i >= 20,
        directionInterval: i >= 20 ? Math.max(3000 - i * 50, 1000) : 0,
        minDiff:           Math.max(0.28 - i * 0.002, 0.18)
      })
    }
    return levels
  }
}