import { z } from 'zod';

/**
 * @constant BASE_CURRENCY
 * @description The currency every stored rate is expressed against. The client keeps its whole budget in euros.
 */
export const BASE_CURRENCY = 'EUR';

/**
 * @constant PROVIDER_BASE_URL
 * @description Frankfurter, a key-free mirror of the European Central Bank reference rates. The ECB publishes
 * once per working day, so neither endpoint below returns a quote for a weekend or a holiday.
 */
export const PROVIDER_BASE_URL = 'https://api.frankfurter.dev/v1';

/**
 * @constant IsoDaySchema
 * @description Zod schema for a calendar day in YYYY-MM-DD form, the way the provider keys its quotes.
 */
export const IsoDaySchema = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

/**
 * @constant CurrencyCodeSchema
 * @description Zod schema for an ISO 4217 alphabetic currency code.
 */
export const CurrencyCodeSchema = z.string().regex(/^[A-Z]{3}$/);

/**
 * @constant ProviderPayloadSchema
 * @description Zod schema for the upstream reference-rate payload. The provider quotes how many units of each
 * currency one euro buys, which is the inverse of what the client stores.
 */
export const ProviderPayloadSchema = z.object({
    base: z.literal(BASE_CURRENCY),
    date: IsoDaySchema,
    rates: z.record(CurrencyCodeSchema, z.number().positive())
});

/**
 * @constant RatesSchema
 * @description Zod schema for the rate snapshot served to the client. Every value in `rates` is the number of
 * euros one unit of that currency buys, matching the client's `rateToEuro` convention.
 */
export const RatesSchema = z.object({
    base: z.literal(BASE_CURRENCY),
    quoteDate: IsoDaySchema,
    fetchedAt: z.coerce.date(),
    rates: z.record(CurrencyCodeSchema, z.number().positive())
});

/**
 * @constant TimeSeriesPayloadSchema
 * @description Zod schema for the upstream payload covering a range of days, keyed by the day each set of
 * quotes was published on. Days the ECB did not publish on are simply absent.
 */
export const TimeSeriesPayloadSchema = z.object({
    base: z.literal(BASE_CURRENCY),
    start_date: IsoDaySchema,
    end_date: IsoDaySchema,
    rates: z.record(IsoDaySchema, z.record(CurrencyCodeSchema, z.number().positive()))
});

/**
 * @type TimeSeriesPayload
 * @description Inferred type for the upstream ranged payload.
 */
export type TimeSeriesPayload = z.infer<typeof TimeSeriesPayloadSchema>;

/**
 * @type RatesBody
 * @description Inferred type for the rate snapshot served to the client.
 */
export type RatesBody = z.infer<typeof RatesSchema>;

/**
 * @type ProviderPayload
 * @description Inferred type for the upstream reference-rate payload.
 */
export type ProviderPayload = z.infer<typeof ProviderPayloadSchema>;
