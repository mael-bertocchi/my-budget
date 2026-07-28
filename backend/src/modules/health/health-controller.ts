import type { FastifyReply, FastifyRequest } from 'fastify';
import { StatusCodes } from 'http-status-codes';

/**
 * @function getHealth
 * @description Reports service liveness and database connectivity.
 *
 * @returns {Promise<void>} Resolves when the health payload is sent.
 */
async function getHealth(request: FastifyRequest, reply: FastifyReply): Promise<void> {
    await request.server.prisma.$queryRaw`SELECT 1`;

    reply.status(StatusCodes.OK).send({ data: { status: 'ok', time: new Date().toISOString() } });
}

export default {
    getHealth
};
