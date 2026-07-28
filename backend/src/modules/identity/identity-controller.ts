import type { FastifyReply, FastifyRequest } from 'fastify';
import { StatusCodes } from 'http-status-codes';
import type { LoginRequest, LogoutRequest, RefreshRequest } from 'src/modules/identity/identity-models';
import { OWNER_ID } from 'src/plugins/identity';
import { RequestError } from 'src/shared/models';

/**
 * @function login
 * @description Verifies the username and password against the env-configured account and returns a fresh access/refresh token pair.
 *
 * @returns {Promise<void>} Resolves when the tokens are sent.
 */
async function login(request: FastifyRequest<LoginRequest>, reply: FastifyReply): Promise<void> {
    if (!request.server.identity.verifyCredentials(request.body.username, request.body.password)) {
        throw new RequestError(StatusCodes.UNAUTHORIZED, 'Invalid username or password');
    }

    const tokens = await request.server.identity.issueTokens(OWNER_ID);

    reply.status(StatusCodes.OK).send({ data: tokens });
}

/**
 * @function refresh
 * @description Rotates an access/refresh token pair from a valid refresh token.
 *
 * @returns {Promise<void>} Resolves when the new tokens are sent.
 */
async function refresh(request: FastifyRequest<RefreshRequest>, reply: FastifyReply): Promise<void> {
    const tokens = await request.server.identity.rotateTokens(request.body.refreshToken);

    reply.status(StatusCodes.OK).send({ data: tokens });
}

/**
 * @function logout
 * @description Invalidates the caller's current refresh token.
 *
 * @returns {Promise<void>} Resolves when the session is revoked.
 */
async function logout(request: FastifyRequest<LogoutRequest>, reply: FastifyReply): Promise<void> {
    await request.server.identity.revokeSession(request.user.id, request.body.refreshToken);

    reply.status(StatusCodes.OK).send({ data: { message: 'Logged out' } });
}

/**
 * @function me
 * @description Returns the authenticated account's public profile.
 *
 * @returns {Promise<void>} Resolves when the profile is sent.
 */
function me(request: FastifyRequest, reply: FastifyReply): void {
    reply.status(StatusCodes.OK).send({ data: { id: request.user.id, username: request.server.variables.IDENTITY_USERNAME } });
}

export default {
    login,
    refresh,
    logout,
    me
};
