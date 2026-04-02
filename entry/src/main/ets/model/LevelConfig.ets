export interface LevelConfig {
  levelNum:          number
  totalPins:         number
  prePlacedAngles:   number[]
  rotSpeed:          number
  directionChange:   boolean
  directionInterval: number
  minDiff:           number
}

export interface PinData {
  angle:     number
  num:       number
  prePlaced: boolean
}