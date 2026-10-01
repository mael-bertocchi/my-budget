import { ApiError } from '@core/errors';
import { t } from '@core/i18n';
import type { BudgetDocument, IdentityTokens, RateSnapshot, StoredState } from '@core/models';
import { IdentityTokensSchema, RateSnapshotSchema, StoredStateSchema } from '@core/models';
import type { Maybe } from '@/models';
import { z } from 'zod';

/**
 * @constant PRODUCTION_API_URL
 * @description Where the budget API lives, the same server the app talks to.
 */
const PRODUCTION_API_URL = 'https://api-budget.mael-bertocchi.fr';

/**
 * @constant API_URL
 * @description The origin every request goes to. A build can point elsewhere with `VITE_API_URL`; in development the
 * page calls its own origin, which the development server forwards to the local backend.
 */
const API_URL = import.meta.env.VITE_API_URL || (import.meta.env.DEV ? '' : PRODUCTION_API_URL);

/**
 * @constant STORAGE_KEY
 * @description Where the session's tokens are kept. Session storage survives a reload but not closing the tab, so the
 * page asks for the code again each time it is opened.
 */
const STORAGE_KEY = 'my-budget.identity';

/**
 * @constant REQUEST_TIMEOUT
 * @description How long to wait on the server before calling it unreachable.
 */
const REQUEST_TIMEOUT = 15 * 1000;

/**
 * @constant GATEWAY_ERRORS
 * @description What the proxy in front of the backend answers when it can't reach it: unreachable, not refused.
 */
const GATEWAY_ERRORS = new Set([502, 503, 504]);

/**
 * @constant ThrottleSchema
 * @description The body of a refusal from the sign-in throttle, which says how many seconds are left before it lets codes
 * through again.
 */
const ThrottleSchema = z.object({ data: z.object({ retryAfter: z.number() }) });

/**
 * @function refusal
 * @description What to tell the person when the server turns a request down, in the page's language. The server words
 * its own messages in English for whoever reads its logs, so they are never shown.
 *
 * @param {number} status The HTTP status.
 * @param {unknown} payload The answer's body.
 *
 * @returns {string} The message to show.
 */
function refusal(status: number, payload: unknown): string {
    if (status === 429) {
        const throttle = ThrottleSchema.safeParse(payload);

        return throttle.success ? t('error.throttled', { minutes: Math.max(1, Math.ceil(throttle.data.data.retryAfter / 60)) }) : t('error.tooManyAttempts');
    }

    return status >= 500 ? t('error.unavailable') : t('error.refused');
}

/**
 * @function readTokens
 * @description The stored tokens, if the storage is readable and holds some.
 */
function readTokens(): Maybe<IdentityTokens> {
    try {
        const parsed = IdentityTokensSchema.safeParse(JSON.parse(sessionStorage.getItem(STORAGE_KEY) ?? 'null'));

        return parsed.success ? parsed.data : null;
    } catch {
        return null;
    }
}

/**
 * @function writeTokens
 * @description Stores the tokens, or forgets them.
 */
function writeTokens(tokens: Maybe<IdentityTokens>): void {
    try {
        if (tokens === null) {
            sessionStorage.removeItem(STORAGE_KEY);
        } else {
            sessionStorage.setItem(STORAGE_KEY, JSON.stringify(tokens));
        }
    } catch {
        return;
    }
}

/**
 * @class ApiClient
 * @description Talks to the budget server, which answers the page across origins. It signs in with the six-digit code,
 * renews its tokens when they lapse, and reports when the session is gone for good.
 */
export class ApiClient {
    private tokens: Maybe<IdentityTokens> = readTokens(); /*!> The session's tokens */
    private renewal: Maybe<Promise<boolean>> = null; /*!> The renewal in flight, shared by concurrent calls */
    private endListeners = new Set<() => void>(); /*!> Who to tell when the session can't be renewed */

    /**
     * @member isSignedIn
     * @description Whether a session is open.
     */
    get isSignedIn(): boolean {
        return this.tokens !== null;
    }

    /**
     * @function onSessionEnded
     * @description Registers a listener told when the session lapsed and couldn't be renewed.
     *
     * @returns {() => void} Unregisters it.
     */
    onSessionEnded(listener: () => void): () => void {
        this.endListeners.add(listener);

        return () => {
            this.endListeners.delete(listener);
        };
    }

    /**
     * @function login
     * @description Opens a session with the six-digit code.
     *
     * @param {string} code The code.
     *
     * @returns {Promise<void>} Resolves once signed in; rejects with the server's reason otherwise.
     */
    async login(code: string): Promise<void> {
        const response = await this.send('/v1/identity/login', { method: 'POST', body: JSON.stringify({ code }) });

        if (response.status === 401) {
            throw new ApiError(401, t('error.wrongCode'));
        }

        this.store(await this.unwrap(response, IdentityTokensSchema));
    }

    /**
     * @function logout
     * @description Closes the session on the server, then forgets it. Forgetting it never waits on the server.
     */
    async logout(): Promise<void> {
        const tokens = this.tokens;

        this.store(null);

        if (tokens !== null) {
            await this.send('/v1/identity/logout', { method: 'POST', body: JSON.stringify({ refreshToken: tokens.refreshToken }) }, tokens.accessToken).catch(() => undefined);
        }
    }

    /**
     * @function getState
     * @description Reads the whole budget and its revision.
     */
    async getState(): Promise<StoredState> {
        return await this.request('/v1/state', { method: 'GET' }, StoredStateSchema);
    }

    /**
     * @function putState
     * @description Stores the whole budget on top of the revision it was edited from. Rejects with a conflict when the
     * server has moved past it.
     */
    async putState(document: BudgetDocument, revision: number): Promise<StoredState> {
        return await this.request('/v1/state', { method: 'PUT', body: JSON.stringify({ ...document, revision }) }, StoredStateSchema);
    }

    /**
     * @function rates
     * @description The latest reference rates, in euros per unit.
     */
    async rates(): Promise<RateSnapshot> {
        return await this.request('/v1/rates', { method: 'GET' }, RateSnapshotSchema);
    }

    /**
     * @function ratesOn
     * @description The reference rates of one day, in euros per unit.
     */
    async ratesOn(day: string): Promise<RateSnapshot> {
        return await this.request(`/v1/rates/${day}`, { method: 'GET' }, RateSnapshotSchema);
    }

    /**
     * @function store
     * @description Keeps or forgets the tokens.
     */
    private store(tokens: Maybe<IdentityTokens>): void {
        this.tokens = tokens;
        writeTokens(tokens);
    }

    /**
     * @function request
     * @description Sends an authorized request. A lapsed access token is renewed once and the request replayed; when it
     * can't be, the session is over.
     */
    private async request<T extends z.ZodType>(path: string, init: RequestInit, schema: T): Promise<z.infer<T>> {
        let response = await this.send(path, init, this.tokens?.accessToken);

        if (response.status === 401) {
            if (!(await this.renew())) {
                this.store(null);

                for (const listener of this.endListeners) {
                    listener();
                }

                throw new ApiError(401, t('error.sessionExpired'));
            }

            response = await this.send(path, init, this.tokens?.accessToken);
        }

        return await this.unwrap(response, schema);
    }

    /**
     * @function renew
     * @description Rotates the refresh token into a new pair. Concurrent calls share one rotation.
     *
     * @returns {Promise<boolean>} Whether the session was renewed.
     */
    private async renew(): Promise<boolean> {
        this.renewal ??= (async () => {
            try {
                if (this.tokens === null) {
                    return false;
                }

                const response = await this.send('/v1/identity/refresh', { method: 'POST', body: JSON.stringify({ refreshToken: this.tokens.refreshToken }) });

                if (!response.ok) {
                    return false;
                }

                this.store(await this.unwrap(response, IdentityTokensSchema));

                return true;
            } finally {
                this.renewal = null;
            }
        })();

        return await this.renewal;
    }

    /**
     * @function send
     * @description Sends one request, turning a network failure into an offline `ApiError`.
     */
    private async send(path: string, init: RequestInit, accessToken?: string): Promise<Response> {
        const headers: Record<string, string> = { Accept: 'application/json' };

        if (init.body !== undefined) {
            headers['Content-Type'] = 'application/json';
        }

        if (accessToken !== undefined) {
            headers.Authorization = `Bearer ${accessToken}`;
        }

        try {
            return await fetch(`${API_URL}${path}`, { ...init, headers, signal: AbortSignal.timeout(REQUEST_TIMEOUT) });
        } catch {
            throw new ApiError(0, t('error.unreachable'));
        }
    }

    /**
     * @function unwrap
     * @description Reads a response's `{ data }` envelope, or turns an error answer into an `ApiError` saying why in the
     * page's language.
     */
    private async unwrap<T extends z.ZodType>(response: Response, schema: T): Promise<z.infer<T>> {
        const payload: unknown = await response.json().catch(() => null);

        if (!response.ok) {
            const hasMessage = typeof payload === 'object' && payload !== null && 'message' in payload && typeof payload.message === 'string';

            if (!hasMessage && GATEWAY_ERRORS.has(response.status)) {
                throw new ApiError(0, t('error.unreachable'));
            }

            throw new ApiError(response.status, refusal(response.status, payload));
        }

        const parsed = schema.safeParse(typeof payload === 'object' && payload !== null && 'data' in payload ? payload.data : undefined);

        if (!parsed.success) {
            throw new ApiError(response.status, t('error.unexpected'));
        }

        return parsed.data;
    }
}
