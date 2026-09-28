import { ApiClient } from '@core/api';
import { ApiError } from '@core/errors';
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

    it("keeps the backend's own message when it answers an error itself", async () => {
        answer(503, JSON.stringify({ message: 'Exchange rates are unavailable', data: null }));

        await expect(new ApiClient().login('123456')).rejects.toMatchObject({ status: 503, message: 'Exchange rates are unavailable' });
    });

    it('passes on why a code was refused', async () => {
        answer(401, JSON.stringify({ message: 'Wrong code', data: null }));

        await expect(new ApiClient().login('123456')).rejects.toMatchObject({ status: 401, message: 'Wrong code' });
    });
});
