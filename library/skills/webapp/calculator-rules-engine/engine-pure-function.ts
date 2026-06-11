/**
 * calculator-rules-engine — pure function engine
 * calculator-rules-engine skill v1.0.0
 *
 * GWARANCJE:
 * - Deterministyczny: te same inputs → te same outputs zawsze
 * - Zero side-effects: brak console.log, fetch, Date.now, Math.random
 * - Fail-fast: nieznany element pricing → RulesNotFoundError (NIE silent 0)
 * - Snapshot-testable: output w pełni serializowalny
 */

import { z } from 'zod';
import { parse as parseYaml } from 'yaml';
import * as fs from 'fs';

// ─── Schema Zod ──────────────────────────────────────────────────────────────

const PricingItemSchema = z.object({
  min: z.number.positive('min musi być > 0'),
  max: z.number.positive('max musi być > 0'),
  unit: z.enum(['PLN/m²', 'PLN/m³', 'PLN/szt', 'PLN/mb']),
  notes: z.string.optional,
}).refine(d => d.max >= d.min, {
  message: 'max musi być >= min',
  path: ['max'],
});

export const RulesSchema = z.object({
  meta: z.object({
    version: z.string.regex(/^\d+\.\d+\.\d+$/, 'Semver MAJOR.MINOR.PATCH wymagany'),
    baseline_date: z.string.regex(/^\d{4}-(0[1-9]|1[0-2])$/, 'Format YYYY-MM'),
    disclaimer: z.string.optional,
    override_source: z.string.optional,
  }),
  pricing: z.record(z.string, PricingItemSchema),
  regional: z.record(z.string, z.number.min(0.85).max(1.20)),
  seasonal: z.record(z.string, z.number.min(0.95).max(1.15)),
});

export type Rules = z.infer<typeof RulesSchema>;

// ─── Typy Input/Output ────────────────────────────────────────────────────────

export interface CalculatorInputs {
  element: string;         // klucz z pricing (np. 'fundament_plytowy')
  quantity: number;        // ilość w jednostkach (m², mb, szt)
  wojewodztwo: string;     // klucz z regional (np. 'mazowieckie')
  month: number;           // 1-12
}

export interface BreakdownItem {
  element: string;
  quantity: number;
  unit: string;
  unitPriceMin: number;
  unitPriceMax: number;
  lineTotalMin: number;
  lineTotalMax: number;
}

export interface AppliedRulesMeta {
  baselineVersion: string;
  regionFactor: number;
  seasonFactor: number;
  overridesApplied: string[];
  warnings: string[];
}

export interface CalculatorResult {
  basePrice: { min: number; max: number };
  regionalAdjusted: { min: number; max: number };
  seasonalAdjusted: { min: number; max: number };
  total: { min: number; max: number };
  breakdown: BreakdownItem[];
  appliedRules: AppliedRulesMeta;
}

// ─── Custom Error ─────────────────────────────────────────────────────────────

export class RulesNotFoundError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RulesNotFoundError';
  }
}

// ─── Helpers (pure) ───────────────────────────────────────────────────────────

function averageOfRecord(record: Record<string, number>): number {
  const values = Object.values(record);
  if (values.length === 0) return 1.0;
  return values.reduce((sum, v) => sum + v, 0) / values.length;
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

// ─── Core: calculate ───────────────────────────────────────────────────────

/**
 * Pure function — deterministyczny kalkulator wyceny GW PL.
 * ZERO side-effects. Rzuca RulesNotFoundError przy braku elementu pricing.
 */
export function calculate(
  inputs: CalculatorInputs,
  rules: Rules,
  overrideSource?: string,
): CalculatorResult {
  const warnings: string[] = [];

  // 1. Cennik — FAIL FAST gdy brak elementu
  const price = rules.pricing[inputs.element];
  if (!price) {
    throw new RulesNotFoundError(
      `Element pricing '${inputs.element}' not found in rules. ` +
      `Available: ${Object.keys(rules.pricing).join(', ')}`
    );
  }

  // 2. Regional factor — fallback: average → 1.0
  let regional = rules.regional[inputs.wojewodztwo];
  if (regional === undefined) {
    const avg = averageOfRecord(rules.regional);
    warnings.push(
      `wojewodztwo '${inputs.wojewodztwo}' not found, using average ${avg.toFixed(3)}`
    );
    regional = avg;
  }

  // 3. Seasonal factor — fallback: 1.0
  const monthKey = String(inputs.month);
  let seasonal = rules.seasonal[monthKey];
  if (seasonal === undefined) {
    warnings.push(`month '${inputs.month}' not found in seasonal, using 1.0`);
    seasonal = 1.0;
  }

  // 4. Calculations (pure arithmetic)
  const baseMin = round2(price.min * inputs.quantity);
  const baseMax = round2(price.max * inputs.quantity);

  const regMin = round2(baseMin * regional);
  const regMax = round2(baseMax * regional);

  const totalMin = round2(regMin * seasonal);
  const totalMax = round2(regMax * seasonal);

  const breakdown: BreakdownItem[] = [{
    element: inputs.element,
    quantity: inputs.quantity,
    unit: price.unit,
    unitPriceMin: price.min,
    unitPriceMax: price.max,
    lineTotalMin: totalMin,
    lineTotalMax: totalMax,
  }];

  return {
    basePrice:        { min: baseMin,  max: baseMax  },
    regionalAdjusted: { min: regMin,   max: regMax   },
    seasonalAdjusted: { min: totalMin, max: totalMax },
    total:            { min: totalMin, max: totalMax },
    breakdown,
    appliedRules: {
      baselineVersion: rules.meta.version,
      regionFactor:    regional,
      seasonFactor:    seasonal,
      overridesApplied: overrideSource ? [overrideSource] : [],
      warnings,
    },
  };
}

// ─── Rules Loader ─────────────────────────────────────────────────────────────

/**
 * Ładuje rules z pliku YAML + waliduje Zod (fail-fast przy invalid).
 * SEMVER CHECK: override MAJOR ≠ baseline MAJOR → WARN (nie FAIL).
 */
export function loadRules(
  baselinePath: string,
  overridePath?: string,
): Rules {
  const baselineRaw = parseYaml(fs.readFileSync(baselinePath, 'utf-8'));
  const baseline = RulesSchema.parse(baselineRaw); // throws ZodError z czytelnym path

  if (!overridePath) return baseline;

  const overrideRaw = parseYaml(fs.readFileSync(overridePath, 'utf-8'));
  const override = RulesSchema.partial.parse(overrideRaw);

  // MAJOR semver check — WARN + continue (nie FAIL)
  const bMajor = parseInt(baseline.meta.version.split('.')[0], 10);
  const oVersion = override.meta?.version ?? baseline.meta.version;
  const oMajor = parseInt(oVersion.split('.')[0], 10);
  if (bMajor !== oMajor) {
    // eslint-disable-next-line no-console -- intentional single warning, not in calculate
    console.warn(
      `[calculator-rules-engine] WARN: override MAJOR (${oMajor}) ` +
      `!= baseline MAJOR (${bMajor}). Continuing with merge.`
    );
  }

  // Deep-merge per section — override wygrywa key-by-key
  return RulesSchema.parse({
    meta: { ...baseline.meta, ...override.meta },
    pricing:  { ...baseline.pricing,  ...override.pricing  },
    regional: { ...baseline.regional, ...override.regional },
    seasonal: { ...baseline.seasonal, ...override.seasonal },
  });
}

// ─── Snapshot Test Pattern ────────────────────────────────────────────────────
//
// Użycie w __tests__/calculate.snapshot.test.ts:
//
// import { calculate, loadRules } from '../engine-pure-function';
//
// const rules = loadRules('src/rules/sample-rules-baseline.yaml');
//
// describe('calculate snapshots',  => {
//   test('dom 150m² mazowieckie marzec',  => {
//     expect(calculate(
//       { element: 'fundament_plytowy', quantity: 150,
//         wojewodztwo: 'mazowieckie', month: 3 },
//       rules
//     )).toMatchSnapshot;
//   });
//
//   test('bliziniak 100m² podlaskie grudzien',  => {
//     expect(calculate(
//       { element: 'mur_ytong_24cm', quantity: 100,
//         wojewodztwo: 'podlaskie', month: 12 },
//       rules
//     )).toMatchSnapshot;
//   });
//
//   test('nieznany element throws RulesNotFoundError',  => {
//     expect( => calculate(
//       { element: 'nieistniejacy_element', quantity: 50,
//         wojewodztwo: 'mazowieckie', month: 6 },
//       rules
//     )).toThrow('RulesNotFoundError');
//   });
// });
//
// Zasada: .snap file commitowany do git.
// Update: npx jest --updateSnapshot + commit "fix(rules): update cennik Q2-2026"
