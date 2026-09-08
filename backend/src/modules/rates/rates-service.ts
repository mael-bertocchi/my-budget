import type { FastifyBaseLogger } from 'fastify';
import { StatusCodes } from 'http-status-codes';
import type { ExchangeRateSnapshot, PrismaClient } from 'prisma/generated/prisma/client';
import type { ProviderPayload, RatesBody } from 'src/modules/rates/rates-models';
import { BASE_CURRENCY, PROVIDER_BASE_URL, ProviderPayloadSchema } from 'src/modules/rates/rates-models';
import { RequestError } from 'src/shared/models';

/**
 * @constant SNAPSHOT_ID
 * @description Primary key of the single row holding the most recently fetched snapshot.
 */
const SNAPSHOT_ID = 'latest';

/**
 * @constant PROVIDER_URL
 * @description The provider endpoint carrying the most recently published reference rates.
 */
const PROVIDER_URL = `${PROVIDER_BASE_URL}/latest?base=${BASE_CURRENCY}`;

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
 * @description Queries the upstream provider and validates its payload.
 *
 * @returns {Promise<ProviderPayload>} The validated upstream payload.
 */
async function fetchProvider(): Promise<ProviderPayload> {
    const response = await fetch(PROVIDER_URL, {
        headers: { Accept: 'application/json' },
        signal: AbortSignal.timeout(PROVIDER_TIMEOUT)
    });

    if (!response.ok) {
        throw new Error(`Rate provider answered ${response.status}`);
    }

    return ProviderPayloadSchema.parse(await response.json());
}

/**
 * @function pullRates
 * @description Returns the current reference rates, refreshing the stored snapshot from the provider when it has
 * gone stale. A provider outage is never fatal while a snapshot exists: the stored one is served instead, and its
 * `fetchedAt` lets the client judge how old it is.
 *
 * @param {PrismaClient} prisma The database client.
 * @param {FastifyBaseLogger} logger The request logger.
 *
 * @returns {Promise<RatesBody>} The rate snapshot, in the client's euros-per-unit convention.
 */
export async function pullRates(prisma: PrismaClient, logger: FastifyBaseLogger): Promise<RatesBody> {
    const cached = await prisma.exchangeRateSnapshot.findUnique({ where: { id: SNAPSHOT_ID } });

    if (cached !== null && Date.now() - cached.fetchedAt.getTime() < REFRESH_AFTER) {
        return toBody(cached);
    }

    let payload: ProviderPayload;

    try {
        payload = await fetchProvider();
    } catch (error: unknown) {
        if (cached === null) {
            logger.error({ error }, 'Rate provider unreachable and no snapshot stored');

            throw new RequestError(StatusCodes.SERVICE_UNAVAILABLE, 'Exchange rates are unavailable');
        }

        logger.warn({ error, fetchedAt: cached.fetchedAt }, 'Rate provider unreachable, serving the stored snapshot');

        return toBody(cached);
    }

    const rates = toEuroRates(payload.rates);
    const fetchedAt = new Date();

    await prisma.exchangeRateSnapshot.upsert({
        where: { id: SNAPSHOT_ID },
        update: { quoteDate: payload.date, rates, fetchedAt },
        create: { id: SNAPSHOT_ID, quoteDate: payload.date, rates, fetchedAt }
    });

    return { base: BASE_CURRENCY, quoteDate: payload.date, fetchedAt, rates };
}
