/**
 * 回答評価から付与ポイントを算出する。
 *
 * iOS 側 `PointCalculator` / `Rank.multiplier` と**完全に一致**させること:
 * - 基本ポイント: 1=10 / 2=50 / 3=100 / 4=150 / 5=250
 * - ランク歩率: S=2.0 / A=1.5 / B=1.0
 * - 付与 = floor(基本 × 歩率)（Swift の `Int(Double(base) * multiplier)` 相当）
 */

const basePointsByStars: Record<number, number> = {
  1: 10,
  2: 50,
  3: 100,
  4: 150,
  5: 250,
};

const multiplierByRank: Record<string, number> = {
  S: 2.0,
  A: 1.5,
  B: 1.0,
};

export interface PointBreakdown {
  basePoints: number;
  multiplier: number;
  pointsAwarded: number;
}

/**
 * @param stars 1〜5 の評価値
 * @param rank 回答者ランク（"S" / "A" / "B"）
 * @returns 基本ポイント・歩率・最終付与ポイント。範囲外の stars は 0。
 */
export function calculatePoints(stars: number, rank: string): PointBreakdown {
  const basePoints = basePointsByStars[stars] ?? 0;
  const multiplier = multiplierByRank[rank] ?? 1.0;
  return {
    basePoints,
    multiplier,
    pointsAwarded: Math.floor(basePoints * multiplier),
  };
}
