import type { FastifyReply, FastifyRequest } from 'fastify';
import { StatusCodes } from 'http-status-codes';
import type { StatePushRequest } from 'src/modules/state/state-models';
import { pullState, pushState } from 'src/modules/state/state-service';

/**
 * @function getState
 * @description Returns the owner's whole budget document (categories, operations, goals, movements, savings).
 *
 * @returns {Promise<void>} Resolves when the document is sent.
 */
async function getState(request: FastifyRequest, reply: FastifyReply): Promise<void> {
    const state = await pullState(request.server.prisma);

    reply.status(StatusCodes.OK).send({ data: state });
}

/**
 * @function putState
 * @description Replaces the owner's whole budget document with the pushed one and returns the stored result.
 *
 * @returns {Promise<void>} Resolves when the stored document is sent.
 */
async function putState(request: FastifyRequest<StatePushRequest>, reply: FastifyReply): Promise<void> {
    const state = await pushState(request.server.prisma, request.body);

    reply.status(StatusCodes.OK).send({ data: state });
}

export default {
    getState,
    putState
};
