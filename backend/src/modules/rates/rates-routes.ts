import type { FastifyInstance } from 'fastify';
import ratesController from 'src/modules/rates/rates-controller';

/**
 * @function ratesRoutes
 * @description Defines the exchange-rate route (read the current euro reference rates).
 */
export default function (fastify: FastifyInstance): void {
    fastify.get('/', {
        preHandler: [fastify.identity.authenticate]
    }, ratesController.getRates);
}
