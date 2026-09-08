import type { FastifyBaseLogger } from 'fastify';
import type { PrismaClient } from 'prisma/generated/prisma/client';
import { pullRates } from 'src/modules/rates/rates-service';
import { RequestError } from 'src/shared/models';
import { afterEach, describe, expect, it, vi } from 'vitest';

const providerPayload = {
    base: 'EUR',
    date: '2026-09-07',
    rates: { CHF: 0.9405, KRW: 1566.56, USD: 1.1622 }
};

/**
 * @function makePrisma
 * @description Builds a Prisma stand-in whose snapshot row is whatever the test wants it to be.
 */
function makePrisma(snapshot: unknown) {
    const upsert = vi.fn(({ create }: { create: unknown }) => Promise.resolve(create));
    const findUnique = vi.fn(() => Promise.resolve(snapshot));

    return {
        prisma: { exchangeRateSnapshot: { findUnique, upsert } } as unknown as PrismaClient,
        findUnique,
        upsert
    };
}

/**
 * @function makeLogger
 * @description Builds a logger stand-in that records what the service reported.
 */
function makeLogger() {
    const logger = { warn: vi.fn(), error: vi.fn() };

    return { logger: logger as unknown as FastifyBaseLogger, warn: logger.warn, error: logger.error };
}

afterEach(() => {
    vi.unstubAllGlobals();
});

describe('pullRates', () => {
    it('inverts the provider quotes into euros per unit', async () => {
        vi.stubGlobal('fetch', vi.fn(() => Promise.resolve({ ok: true, json: () => Promise.resolve(providerPayload) })));

        const { prisma } = makePrisma(null);
        const { logger } = makeLogger();
        const result = await pullRates(prisma, logger);

        expect(result.quoteDate).toBe('2026-09-07');
        expect(result.rates.USD).toBeCloseTo(1 / 1.1622, 9);
        expect(result.rates.CHF).toBeCloseTo(1 / 0.9405, 9);
        expect(result.rates.KRW).toBeCloseTo(1 / 1566.56, 9);
    });

    it('quotes the base currency against itself', async () => {
        vi.stubGlobal('fetch', vi.fn(() => Promise.resolve({ ok: true, json: () => Promise.resolve(providerPayload) })));

        const { prisma } = makePrisma(null);
        const { logger } = makeLogger();

        expect((await pullRates(prisma, logger)).rates.EUR).toBe(1);
    });

    it('stores the refreshed snapshot', async () => {
        vi.stubGlobal('fetch', vi.fn(() => Promise.resolve({ ok: true, json: () => Promise.resolve(providerPayload) })));

        const { prisma, upsert } = makePrisma(null);
        const { logger } = makeLogger();

        await pullRates(prisma, logger);

        expect(upsert).toHaveBeenCalledTimes(1);
        expect(upsert.mock.calls[0]?.[0]).toMatchObject({ where: { id: 'latest' } });
    });

    it('serves a recent snapshot without calling the provider', async () => {
        const fetchMock = vi.fn();
        vi.stubGlobal('fetch', fetchMock);

        const { prisma } = makePrisma({
            id: 'latest',
            quoteDate: '2026-09-07',
            rates: { EUR: 1, USD: 0.860437 },
            fetchedAt: new Date()
        });
        const { logger } = makeLogger();
        const result = await pullRates(prisma, logger);

        expect(fetchMock).not.toHaveBeenCalled();
        expect(result.rates.USD).toBe(0.860437);
    });

    it('falls back to the stored snapshot when the provider is unreachable', async () => {
        vi.stubGlobal('fetch', vi.fn(() => Promise.reject(new Error('network down'))));

        const stale = new Date(Date.now() - 48 * 60 * 60 * 1000);
        const { prisma, upsert } = makePrisma({
            id: 'latest',
            quoteDate: '2026-09-05',
            rates: { EUR: 1, USD: 0.859 },
            fetchedAt: stale
        });
        const { logger, warn } = makeLogger();
        const result = await pullRates(prisma, logger);

        expect(result.quoteDate).toBe('2026-09-05');
        expect(result.fetchedAt).toBe(stale);
        expect(upsert).not.toHaveBeenCalled();
        expect(warn).toHaveBeenCalledTimes(1);
    });

    it('reports the outage when the provider is unreachable and nothing is stored', async () => {
        vi.stubGlobal('fetch', vi.fn(() => Promise.reject(new Error('network down'))));

        const { prisma } = makePrisma(null);
        const { logger, error } = makeLogger();

        await expect(pullRates(prisma, logger)).rejects.toBeInstanceOf(RequestError);
        expect(error).toHaveBeenCalledTimes(1);
    });

    it('rejects a provider payload it cannot trust', async () => {
        vi.stubGlobal('fetch', vi.fn(() => Promise.resolve({ ok: true, json: () => Promise.resolve({ base: 'USD', date: '2026-09-07', rates: {} }) })));

        const { prisma } = makePrisma(null);
        const { logger } = makeLogger();

        await expect(pullRates(prisma, logger)).rejects.toBeInstanceOf(RequestError);
    });
});
