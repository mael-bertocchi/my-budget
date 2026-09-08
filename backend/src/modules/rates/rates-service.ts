import type { FastifyBaseLogger } from 'fastify';
import { StatusCodes } from 'http-status-codes';
import type { ExchangeRateSnapshot, PrismaClient } from 'prisma/generated/prisma/client';
import { toIsoDay } from 'src/modules/rates/rates-history';
import type { ProviderPayload, RatesBody } from 'src/modules/rates/rates-models';
import { BASE_CURRENCY, PROVIDER_BASE_URL, ProviderPayloadSchema } from 'src/modules/rates/rates-models';
import { RequestError } from 'src/shared/models';

/**
 * @constant LATEST_ID
 * @description Primary key of the row holding the most recently published rates. Rows for a specific day
 * are keyed by that day instead, so both live and historical lookups share one cache.
 */
const LATEST_ID = 'latest';

/**
 * @function providerUrl
 * @description Builds the provider endpoint for a given day, or for the most recent publication.
 *
 * @param {string} day The day to quote, or 'latest'.
 *
 * @returns {string} The endpoint to query.
 */
function providerUrl(day: string): string {
    return `${PROVIDER_BASE_URL}/${day}?base=${BASE_CURRENCY}`;
}

/**
 * @constant PROVIDER_TIMEOUT
 * @description How long to wait on the provider before giving up and falling back to the stored snapshot.
 */
const PROVIDER_TIMEOUT = 8 * 1000;

/**
 * @constant REFRESH_AFTER
 * @description How old a stored snapshot may get before the provider is queried again. The ECB publishes once
 * per working day around 16:00 CET, so re-checking a few times a day is enough to never miss a publication.
 */
const REFRESH_AFTER = 6 * 60 * 60 * 1000;

/**
 * @function toEuroRates
 * @description Inverts the provider's "units per euro" quotes into the "euros per unit" values the client stores,
 * and adds the identity rate for the base currency itself.
 *
 * @param {ProviderPayload['rates']} rates The provider's quotes, keyed by currency code.
 *
 * @returns {Record<string, number>} Euros bought by one unit of each currency.
 */
function toEuroRates(rates: ProviderPayload['rates']): Record<string, number> {
    const euroRates: Record<string, number> = { [BASE_CURRENCY]: 1 };

    for (const [code, unitsPerEuro] of Object.entries(rates)) {
        euroRates[code] = 1 / unitsPerEuro;
    }

    return euroRates;
}

/**
 * @function toBody
 * @description Maps a stored snapshot row onto the response body.
 *
 * @param {ExchangeRateSnapshot} snapshot The stored snapshot row.
 *
 * @returns {RatesBody} The snapshot in the shape served to the client.
 */
function toBody(snapshot: ExchangeRateSnapshot): RatesBody {
    return {
        base: BASE_CURRENCY,
        quoteDate: snapshot.quoteDate,
        fetchedAt: snapshot.fetchedAt,
        rates: snapshot.rates as Record<string, number>
    };
}

/**
 * @function fetchProvider
 * @description Queries the upstream provider for one day and validates its payload. Asking for a day the ECB
 * did not publish on answers with the most recent publication before it, named in the payload's own date.
 *
 * @param {string} day The day to quote, or 'latest'.
 *
 * @returns {Promise<ProviderPayload>} The validated upstream payload.
 */
async function fetchProvider(day: string): Promise<ProviderPayload> {
    const response = await fetch(providerUrl(day), {
        headers: { Accept: 'application/json' },
        signal: AbortSignal.timeout(PROVIDER_TIMEOUT)
    });

    if (!response.ok) {
        throw new Error(`Rate provider answered ${response.status}`);
    }

    return ProviderPayloadSchema.parse(await response.json());
}

/**
 * @function pullSnapshot
 * @description Returns one cached snapshot, refreshing it from the provider when it is missing or stale. A
 * provider outage is never fatal while a snapshot exists: the stored one is served instead, and its
 * `fetchedAt` lets the client judge how old it is.
 *
 * @param {PrismaClient} prisma The database client.
 * @param {FastifyBaseLogger} logger The request logger.
 * @param {string} day The day to quote, or 'latest' for the most recent publication.
 * @param {boolean} settled Whether the day is finished, making its rates immutable and cacheable forever.
 *
 * @returns {Promise<RatesBody>} The rate snapshot, in the client's euros-per-unit convention.
 */
async function pullSnapshot(prisma: PrismaClient, logger: FastifyBaseLogger, day: string, settled: boolean): Promise<RatesBody> {
    const cached = await prisma.exchangeRateSnapshot.findUnique({ where: { id: day } });

    if (cached !== null && (settled || Date.now() - cached.fetchedAt.getTime() < REFRESH_AFTER)) {
        return toBody(cached);
    }

    let payload: ProviderPayload;

    try {
        payload = await fetchProvider(day);
    } catch (error: unknown) {
        if (cached === null) {
            logger.error({ error, day }, 'Rate provider unreachable and no snapshot stored');

            throw new RequestError(StatusCodes.SERVICE_UNAVAILABLE, 'Exchange rates are unavailable');
        }

        logger.warn({ error, day, fetchedAt: cached.fetchedAt }, 'Rate provider unreachable, serving the stored snapshot');

        return toBody(cached);
    }

    const rates = toEuroRates(payload.rates);
    const fetchedAt = new Date();

    await prisma.exchangeRateSnapshot.upsert({
        where: { id: day },
        update: { quoteDate: payload.date, rates, fetchedAt },
        create: { id: day, quoteDate: payload.date, rates, fetchedAt }
    });

    return { base: BASE_CURRENCY, quoteDate: payload.date, fetchedAt, rates };
}

/**
 * @function pullRates
 * @description Returns the most recently published reference rates.
 *
 * @param {PrismaClient} prisma The database client.
 * @param {FastifyBaseLogger} logger The request logger.
 *
 * @returns {Promise<RatesBody>} The rate snapshot, in the client's euros-per-unit convention.
 */
export async function pullRates(prisma: PrismaClient, logger: FastifyBaseLogger): Promise<RatesBody> {
    return await pullSnapshot(prisma, logger, LATEST_ID, false);
}

/**
 * @function pullRatesForDay
 * @description Returns the reference rates that applied on one day. The ECB does not publish at weekends or on
 * holidays, so the answer names the day it actually came from, which may be earlier than the one asked for.
 * A day that is over can never be republished, so it is cached permanently.
 *
 * @param {PrismaClient} prisma The database client.
 * @param {FastifyBaseLogger} logger The request logger.
 * @param {string} day The day to quote, in YYYY-MM-DD form.
 *
 * @returns {Promise<RatesBody>} The rate snapshot, in the client's euros-per-unit convention.
 */
export async function pullRatesForDay(prisma: PrismaClient, logger: FastifyBaseLogger, day: string): Promise<RatesBody> {
    const today = toIsoDay(new Date());
    const tomorrow = new Date();

    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);

    // A day ahead of UTC is still "today" somewhere, so only reject what no timezone could call the past.
    if (day > toIsoDay(tomorrow)) {
        throw new RequestError(StatusCodes.BAD_REQUEST, 'Exchange rates cannot be requested for a future date');
    }

    return await pullSnapshot(prisma, logger, day, day < today);
}
