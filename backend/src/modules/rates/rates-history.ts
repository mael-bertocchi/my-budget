import { BASE_CURRENCY, PROVIDER_BASE_URL, TimeSeriesPayloadSchema } from 'src/modules/rates/rates-models';
import type { Maybe } from 'src/shared/models';

/**
 * @constant PROVIDER_TIMEOUT
 * @description How long to wait on the provider. A ranged query covers years of quotes in one request,
 * so it is given more room than the single-day lookup.
 */
const PROVIDER_TIMEOUT = 20 * 1000;

/**
 * @interface RateHistory
 * @description Reference rates for a range of days, in the euros-per-unit convention the client stores.
 */
export interface RateHistory {
    days: string[]; /*!< The days the provider published on, ascending */
    rates: Record<string, Record<string, number>>; /*!< Day, then currency code, to euros per unit */
}

/**
 * @function toIsoDay
 * @description Reduces an instant to the UTC calendar day the provider keys its quotes by.
 *
 * @param {Date} date The instant to reduce.
 *
 * @returns {string} The day in YYYY-MM-DD form.
 */
export function toIsoDay(date: Date): string {
    return date.toISOString().slice(0, 10);
}

/**
 * @function fetchHistory
 * @description Pulls every published quote between two days in one request and inverts them into the
 * euros-per-unit convention.
 *
 * @param {string} start The first day to cover, in YYYY-MM-DD form.
 * @param {string} end The last day to cover, in YYYY-MM-DD form.
 * @param {string[]} codes The currency codes to ask for.
 *
 * @returns {Promise<RateHistory>} The published quotes, keyed by day.
 */
export async function fetchHistory(start: string, end: string, codes: string[]): Promise<RateHistory> {
    const symbols = [...new Set(codes)].filter((code) => code !== BASE_CURRENCY).sort();

    if (symbols.length === 0) {
        return { days: [], rates: {} };
    }

    const response = await fetch(`${PROVIDER_BASE_URL}/${start}..${end}?base=${BASE_CURRENCY}&symbols=${symbols.join(',')}`, {
        headers: { Accept: 'application/json' },
        signal: AbortSignal.timeout(PROVIDER_TIMEOUT)
    });

    if (!response.ok) {
        throw new Error(`Rate provider answered ${response.status}`);
    }

    const payload = TimeSeriesPayloadSchema.parse(await response.json());
    const rates: Record<string, Record<string, number>> = {};

    for (const [day, quotes] of Object.entries(payload.rates)) {
        const euroRates: Record<string, number> = {};

        for (const [code, unitsPerEuro] of Object.entries(quotes)) {
            euroRates[code] = 1 / unitsPerEuro;
        }

        rates[day] = euroRates;
    }

    return { days: Object.keys(rates).sort(), rates };
}

/**
 * @function resolveRate
 * @description Returns the rate that applied on a given day, falling back to the most recent day published
 * before it. The ECB does not publish at weekends or on holidays, so a Saturday purchase is converted at
 * Friday's reference rate, which is what a card issuer would have used.
 *
 * @param {RateHistory} history The published quotes to resolve against.
 * @param {Date} date The day the operation happened on.
 * @param {string} code The currency the operation was paid in.
 *
 * @returns {Maybe<number>} The euros one unit bought that day, or null when nothing covers it.
 */
export function resolveRate(history: RateHistory, date: Date, code: string): Maybe<number> {
    if (code === BASE_CURRENCY) {
        return 1;
    }

    const day = toIsoDay(date);

    for (let index = history.days.length - 1; index >= 0; index -= 1) {
        const published = history.days[index];

        if (published > day) {
            continue;
        }

        return history.rates[published]?.[code] ?? null;
    }

    return null;
}
