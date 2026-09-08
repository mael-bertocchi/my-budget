import type { RateHistory } from 'src/modules/rates/rates-history';
import { fetchHistory, resolveRate, toIsoDay } from 'src/modules/rates/rates-history';
import { afterEach, describe, expect, it, vi } from 'vitest';

// 2026-09-05 and 2026-09-06 are a weekend, so the ECB published nothing on them.
const history: RateHistory = {
    days: ['2026-09-03', '2026-09-04', '2026-09-07'],
    rates: {
        '2026-09-03': { USD: 0.862069, CHF: 1.062699 },
        '2026-09-04': { USD: 0.860437, CHF: 1.063264 },
        '2026-09-07': { USD: 0.861030, CHF: 1.061008 }
    }
};

const timeSeriesPayload = {
    amount: 1,
    base: 'EUR',
    start_date: '2026-09-03',
    end_date: '2026-09-07',
    rates: {
        '2026-09-04': { USD: 1.1622 },
        '2026-09-03': { USD: 1.16 },
        '2026-09-07': { USD: 1.1614 }
    }
};

afterEach(() => {
    vi.unstubAllGlobals();
});

describe('toIsoDay', () => {
    it('reduces an instant to its UTC calendar day', () => {
        expect(toIsoDay(new Date('2026-09-05T23:30:00.000Z'))).toBe('2026-09-05');
    });
});

describe('resolveRate', () => {
    it('uses the rate published on the operation\'s own day', () => {
        expect(resolveRate(history, new Date('2026-09-04T12:00:00.000Z'), 'USD')).toBe(0.860437);
    });

    it('falls back to Friday for a Saturday operation', () => {
        expect(resolveRate(history, new Date('2026-09-05T12:00:00.000Z'), 'USD')).toBe(0.860437);
    });

    it('falls back to Friday for a Sunday operation', () => {
        expect(resolveRate(history, new Date('2026-09-06T20:00:00.000Z'), 'CHF')).toBe(1.063264);
    });

    it('quotes the base currency against itself', () => {
        expect(resolveRate(history, new Date('2026-09-05T12:00:00.000Z'), 'EUR')).toBe(1);
    });

    it('uses the most recent day for an operation past the end of the range', () => {
        expect(resolveRate(history, new Date('2026-09-30T12:00:00.000Z'), 'USD')).toBe(0.861030);
    });

    it('returns nothing for an operation before the range starts', () => {
        expect(resolveRate(history, new Date('2026-09-01T12:00:00.000Z'), 'USD')).toBeNull();
    });

    it('returns nothing for a currency the provider does not quote', () => {
        expect(resolveRate(history, new Date('2026-09-04T12:00:00.000Z'), 'KRW')).toBeNull();
    });
});

describe('fetchHistory', () => {
    it('inverts every quote and sorts the published days', async () => {
        vi.stubGlobal('fetch', vi.fn(() => Promise.resolve({ ok: true, json: () => Promise.resolve(timeSeriesPayload) })));

        const result = await fetchHistory('2026-09-03', '2026-09-07', ['USD', 'EUR', 'USD']);

        expect(result.days).toEqual(['2026-09-03', '2026-09-04', '2026-09-07']);
        expect(result.rates['2026-09-04']?.USD).toBeCloseTo(1 / 1.1622, 9);
    });

    it('asks the provider for each currency once, and never for the base', async () => {
        const fetchMock = vi.fn(() => Promise.resolve({ ok: true, json: () => Promise.resolve(timeSeriesPayload) }));
        vi.stubGlobal('fetch', fetchMock);

        await fetchHistory('2026-09-03', '2026-09-07', ['USD', 'EUR', 'USD']);

        expect(String(fetchMock.mock.calls[0]?.[0])).toContain('symbols=USD');
        expect(String(fetchMock.mock.calls[0]?.[0])).not.toContain('EUR,');
    });

    it('skips the request when only the base currency is asked for', async () => {
        const fetchMock = vi.fn();
        vi.stubGlobal('fetch', fetchMock);

        const result = await fetchHistory('2026-09-03', '2026-09-07', ['EUR']);

        expect(fetchMock).not.toHaveBeenCalled();
        expect(result).toEqual({ days: [], rates: {} });
    });

    it('reports an unhappy provider', async () => {
        vi.stubGlobal('fetch', vi.fn(() => Promise.resolve({ ok: false, status: 503 })));

        await expect(fetchHistory('2026-09-03', '2026-09-07', ['USD'])).rejects.toThrow('503');
    });
});
