import type { FastifyReply, FastifyRequest } from 'fastify';
import { StatusCodes } from 'http-status-codes';
import { pullRates } from 'src/modules/rates/rates-service';

/**
 * @function getRates
 * @description Returns the current euro reference rates, refreshed from the upstream provider when stale.
 *
 * @returns {Promise<void>} Resolves when the rate snapshot is sent.
 */
async function getRates(request: FastifyRequest, reply: FastifyReply): Promise<void> {
    const rates = await pullRates(request.server.prisma, request.log);

    reply.status(StatusCodes.OK).send({ data: rates });
}

export default {
    getRates
};
