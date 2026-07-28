import { createHash, randomUUID, timingSafeEqual } from 'node:crypto';

import fastifyJwt from '@fastify/jwt';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import fp from 'fastify-plugin';
import { StatusCodes } from 'http-status-codes';
import { RequestError } from 'src/shared/models';

/**
 * @constant OWNER_ID
 * @description The single account's stable identifier. Everything the API stores belongs to it.
 */
export const OWNER_ID = 'owner';

/**
 * @interface TokenPayload
 * @description The signed JWT payload. Refresh tokens additionally carry the id of their persisted session.
 */
export interface TokenPayload {
    id: string; /*!< The owner's identifier */
    type: 'access' | 'refresh'; /*!< Distinguishes an access token from a refresh token */
    sid?: string; /*!< Refresh-session id, present on refresh tokens only */
}

/**
 * @interface IdentityTokens
 * @description A freshly minted access/refresh token pair.
 */
export interface IdentityTokens {
    accessToken: string; /*!< Short-lived bearer access token */
    refreshToken: string; /*!< Long-lived refresh token, backed by a persisted session */
}

/**
 * @interface IdentityService
 * @description Public interface exposed on the Fastify instance.
 */
export interface IdentityService {
    verifyCredentials: (username: string, password: string) => boolean; /*!< Constant-time check of the env-configured username and password */
    issueTokens: (userId: string) => Promise<IdentityTokens>; /*!< Creates a refresh session and returns a token pair */
    rotateTokens: (refreshToken: string) => Promise<IdentityTokens>; /*!< Validates and rotates a refresh token into a new pair */
    revokeSession: (userId: string, refreshToken: string) => Promise<void>; /*!< Invalidates a single refresh session (logout) */
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>; /*!< preHandler guarding a route with a bearer access token */
}

/**
 * @function constantTimeEquals
 * @description Compares two strings without leaking their length or content through timing. Both sides are hashed to a fixed-width digest first so the comparison is always over equal-length buffers.
 */
function constantTimeEquals(left: string, right: string): boolean {
    const leftDigest = createHash('sha256').update(left).digest();
    const rightDigest = createHash('sha256').update(right).digest();

    return timingSafeEqual(leftDigest, rightDigest);
}

/**
 * @function identityPlugin
 * @description Registers JWT signing/verification, persisted refresh sessions, and the route guard for the single env-configured account.
 */
export default fp(async function (fastify: FastifyInstance): Promise<void> {
    await fastify.register(fastifyJwt, {
        secret: fastify.variables.JWT_SECRET
    });

    /**
     * @function verifyRefresh
     * @description Verifies a refresh token's signature and shape, returning its owner and session ids.
     */
    const verifyRefresh = (token: string): { id: string; sid: string } => {
        let payload: TokenPayload;

        try {
            payload = fastify.jwt.verify<TokenPayload>(token);
        } catch {
            throw new RequestError(StatusCodes.UNAUTHORIZED, 'Invalid or expired refresh token');
        }

        if (payload.type !== 'refresh' || payload.sid === undefined) {
            throw new RequestError(StatusCodes.UNAUTHORIZED, 'Invalid refresh token');
        }

        return { id: payload.id, sid: payload.sid };
    };

    /**
     * @function issueTokens
     * @description Persists a new refresh session and returns the matching access/refresh token pair.
     */
    const issueTokens = async (userId: string): Promise<IdentityTokens> => {
        const sid = randomUUID();
        const refreshToken = fastify.jwt.sign({ id: userId, type: 'refresh', sid }, { expiresIn: fastify.variables.JWT_REFRESH_EXPIRY });
        const decoded = fastify.jwt.decode<{ exp: number }>(refreshToken);
        const expiresAt = decoded !== null ? new Date(decoded.exp * 1000) : new Date();

        await fastify.prisma.refreshSession.create({ data: { id: sid, userId, expiresAt } });

        const accessToken = fastify.jwt.sign({ id: userId, type: 'access' }, { expiresIn: fastify.variables.JWT_ACCESS_EXPIRY });

        return { accessToken, refreshToken };
    };

    const authenticate = async (request: FastifyRequest, _reply: FastifyReply): Promise<void> => {
        try {
            await request.jwtVerify();
        } catch {
            throw new RequestError(StatusCodes.UNAUTHORIZED, 'Invalid or expired access token');
        }

        if (request.user.type !== 'access') {
            throw new RequestError(StatusCodes.UNAUTHORIZED, 'Invalid access token');
        }
    };

    fastify.decorate('identity', {
        verifyCredentials(username: string, password: string): boolean {
            const usernameMatches = constantTimeEquals(username, fastify.variables.IDENTITY_USERNAME);
            const passwordMatches = constantTimeEquals(password, fastify.variables.IDENTITY_PASSWORD);

            return usernameMatches && passwordMatches;
        },

        issueTokens,

        async rotateTokens(refreshToken: string): Promise<IdentityTokens> {
            const { id, sid } = verifyRefresh(refreshToken);

            const session = await fastify.prisma.refreshSession.findUnique({ where: { id: sid } });

            if (session === null || session.userId !== id || session.expiresAt.getTime() <= Date.now()) {
                throw new RequestError(StatusCodes.UNAUTHORIZED, 'Invalid or expired refresh token');
            }

            await fastify.prisma.refreshSession.delete({ where: { id: sid } });

            return await issueTokens(id);
        },

        async revokeSession(userId: string, refreshToken: string): Promise<void> {
            const { id, sid } = verifyRefresh(refreshToken);

            if (id !== userId) {
                throw new RequestError(StatusCodes.UNAUTHORIZED, 'Invalid refresh token');
            }

            await fastify.prisma.refreshSession.deleteMany({ where: { id: sid, userId } });
        },

        authenticate
    });
}, {
    name: 'identity',
    dependencies: ['environment', 'database']
});
