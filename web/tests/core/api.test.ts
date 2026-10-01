import { ApiClient } from '@core/api';
import { ApiError } from '@core/errors';
import { chooseLanguage } from '@core/i18n';
import { afterEach, describe, expect, it, vi } from 'vitest';

afterEach(() => {
    vi.unstubAllGlobals();
});

/**
 * @function answer
 * @description Makes every request get the same answer.
 */
function answer(status: number, body: string, contentType = 'application/json'): void {
    vi.stubGlobal('fetch', vi.fn(() => Promise.resolve(new Response(body, { status, headers: { 'Content-Type': contentType } }))));
}

describe('ApiClient', () => {
    it("reports the proxy's gateway error as an unreachable server", async () => {
        answer(502, '<html>502 Bad Gateway</html>', 'text/html');

        const failure = new ApiClient().login('123456');

        await expect(failure).rejects.toBeInstanceOf(ApiError);
        await expect(failure).rejects.toMatchObject({ status: 0, message: "Can't reach the server." });
    });

    it("words the backend's own errors in the page's language", async () => {
        answer(503, JSON.stringify({ message: 'Exchange rates are unavailable', data: null }));

        await expect(new ApiClient().login('123456')).rejects.toMatchObject({ status: 503, message: 'The server is unavailable right now.' });
    });

    it('says a code was wrong', async () => {
        answer(401, JSON.stringify({ message: 'Wrong code', data: null }));

        await expect(new ApiClient().login('123456')).rejects.toMatchObject({ status: 401, message: 'Wrong code.' });
    });

    it('says how long the sign-in throttle holds', async () => {
        answer(429, JSON.stringify({ message: 'Too many wrong codes. Try again in 3 minutes.', data: { retryAfter: 125 } }));

        await expect(new ApiClient().login('123456')).rejects.toMatchObject({ status: 429, message: 'Too many wrong codes. Try again in 3 min.' });
    });

    it('asks to wait a moment when rate-limited without a delay', async () => {
        answer(429, JSON.stringify({ message: 'Rate limit exceeded, retry in 1 minute', statusCode: 429 }));

        await expect(new ApiClient().login('123456')).rejects.toMatchObject({ status: 429, message: 'Too many attempts. Try again in a moment.' });
    });

    it('speaks French when the page does', async () => {
        chooseLanguage('fr');
        answer(401, JSON.stringify({ message: 'Wrong code', data: null }));

        await expect(new ApiClient().login('123456')).rejects.toMatchObject({ status: 401, message: 'Code incorrect.' });
    });
});
