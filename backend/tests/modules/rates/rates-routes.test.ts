import type { FastifyInstance } from 'fastify';
import Fastify from 'fastify';
import { StatusCodes } from 'http-status-codes';
import ratesRoutes from 'src/modules/rates/rates-routes';
import { RequestError } from 'src/shared/models';
import { describe, expect, it, vi } from 'vitest';

const storedSnapshot = {
    id: 'latest',
    quoteDate: '2026-09-08',
    rates: { EUR: 1, USD: 0.861029, CHF: 1.061007, KRW: 0.000641 },
    fetchedAt: new Date()
};

/**
 * @function buildApp
 * @description Builds an instance carrying just the decorations the rates routes depend on, so the route
 * wiring and its guard can be exercised without a database.
 */
async function buildApp(authenticate: () => Promise<void>): Promise<{ app: FastifyInstance; findUnique: ReturnType<typeof vi.fn> }> {
    const findUnique = vi.fn(() => Promise.resolve(storedSnapshot));
    const app = Fastify();

    app.decorate('prisma', { exchangeRateSnapshot: { findUnique, upsert: vi.fn() } } as never);
    app.decorate('identity', { authenticate } as never);

    app.setErrorHandler((error: Error, _request, reply) => {
        const code = error instanceof RequestError ? error.code : StatusCodes.INTERNAL_SERVER_ERROR;

        return reply.status(code).send({ message: error.message, data: undefined });
    });

    await app.register(ratesRoutes, { prefix: '/v1/rates' });

    return { app, findUnique };
}

/**
 * @function allow
 * @description An authenticate stand-in that lets the request through.
 */
function allow(): Promise<void> {
    return Promise.resolve();
}

/**
 * @function deny
 * @description An authenticate stand-in that rejects the request the way the real guard does.
 */
function deny(): Promise<void> {
    return Promise.reject(new RequestError(StatusCodes.UNAUTHORIZED, 'Invalid or expired access token'));
}

describe('GET /v1/rates', () => {
    it('serves the snapshot inside the standard envelope', async () => {
        const { app } = await buildApp(allow);
        const response = await app.inject({ method: 'GET', url: '/v1/rates' });

        expect(response.statusCode).toBe(StatusCodes.OK);

        const body = response.json<{ data: { base: string; quoteDate: string; rates: Record<string, number> } }>();

        expect(body.data.base).toBe('EUR');
        expect(body.data.quoteDate).toBe('2026-09-08');
        expect(body.data.rates.USD).toBe(0.861029);

        await app.close();
    });

    it('is guarded by the identity plugin', async () => {
        const { app, findUnique } = await buildApp(deny);
        const response = await app.inject({ method: 'GET', url: '/v1/rates' });

        expect(response.statusCode).toBe(StatusCodes.UNAUTHORIZED);
        expect(findUnique).not.toHaveBeenCalled();

        await app.close();
    });
});
