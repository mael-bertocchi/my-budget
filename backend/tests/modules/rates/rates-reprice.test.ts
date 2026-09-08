import type { RateHistory } from 'src/modules/rates/rates-history';
import type { RepriceableOperation } from 'src/modules/rates/rates-reprice';
import { planReprice } from 'src/modules/rates/rates-reprice';
import { describe, expect, it } from 'vitest';

// 2026-09-05 and 2026-09-06 are a weekend, so the ECB published nothing on them.
const history: RateHistory = {
    days: ['2026-09-03', '2026-09-04', '2026-09-07'],
    rates: {
        '2026-09-03': { USD: 0.862069 },
        '2026-09-04': { USD: 0.860437 },
        '2026-09-07': { USD: 0.861030 }
    }
};

/**
 * @function operation
 * @description Builds a stored operation with the fields the pass reads.
 */
function operation(overrides: Partial<RepriceableOperation> = {}): RepriceableOperation {
    return {
        id: 'operation-1',
        date: new Date('2026-09-04T18:00:00.000Z'),
        name: 'Whole Foods',
        amount: 100,
        currencyCode: 'USD',
        rateToEuro: 0.9207,
        ...overrides
    };
}

describe('planReprice', () => {
    it('re-prices an operation stored at the stale constant', () => {
        const { changes } = planReprice([operation()], history);

        expect(changes).toHaveLength(1);
        expect(changes[0]?.oldRate).toBe(0.9207);
        expect(changes[0]?.newRate).toBe(0.860437);
        expect(changes[0]?.oldEuro).toBeCloseTo(92.07, 6);
        expect(changes[0]?.newEuro).toBeCloseTo(86.0437, 6);
    });

    it('prices a weekend operation at the preceding published day', () => {
        const saturday = operation({ date: new Date('2026-09-05T12:00:00.000Z') });
        const { changes } = planReprice([saturday], history);

        expect(changes[0]?.newRate).toBe(0.860437);
        expect(changes[0]?.date).toBe('2026-09-05');
    });

    it('leaves operations already in the base currency alone', () => {
        const plan = planReprice([operation({ currencyCode: 'EUR', rateToEuro: 1 })], history);

        expect(plan.scanned).toBe(0);
        expect(plan.changes).toHaveLength(0);
        expect(plan.skipped).toHaveLength(0);
    });

    it('leaves an operation already at its historical rate alone, so the pass can be re-run', () => {
        const plan = planReprice([operation({ rateToEuro: 0.860437 })], history);

        expect(plan.scanned).toBe(1);
        expect(plan.changes).toHaveLength(0);
    });

    it('sets aside operations no published rate covers, rather than guessing', () => {
        const uncovered = operation({ id: 'operation-2', date: new Date('2026-08-01T12:00:00.000Z') });
        const plan = planReprice([operation(), uncovered], history);

        expect(plan.changes).toHaveLength(1);
        expect(plan.skipped).toHaveLength(1);
        expect(plan.skipped[0]?.id).toBe('operation-2');
    });

    it('sets aside a currency the provider does not quote', () => {
        const plan = planReprice([operation({ currencyCode: 'KRW', rateToEuro: 0.00063 })], history);

        expect(plan.changes).toHaveLength(0);
        expect(plan.skipped).toHaveLength(1);
    });
});
