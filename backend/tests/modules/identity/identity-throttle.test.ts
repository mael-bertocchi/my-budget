import { FAILURE_WINDOW, MAX_FAILURES, SignInThrottle } from 'src/modules/identity/identity-throttle';
import { describe, expect, it } from 'vitest';

describe('SignInThrottle', () => {
    it('stays open below the failure cap', () => {
        const throttle = new SignInThrottle();

        for (let failure = 1; failure < MAX_FAILURES; failure += 1) {
            throttle.recordFailure(failure * 1000);
        }

        expect(throttle.retryAfter(MAX_FAILURES * 1000)).toBe(0);
    });

    it('closes once the cap is reached, until the oldest failure leaves the window', () => {
        const throttle = new SignInThrottle();

        for (let failure = 0; failure < MAX_FAILURES; failure += 1) {
            throttle.recordFailure(failure * 1000);
        }

        expect(throttle.retryAfter(MAX_FAILURES * 1000)).toBe(FAILURE_WINDOW - MAX_FAILURES * 1000);
        expect(throttle.retryAfter(FAILURE_WINDOW)).toBe(0);
    });

    it('forgets every failure once the right code comes in', () => {
        const throttle = new SignInThrottle();

        for (let failure = 0; failure < MAX_FAILURES; failure += 1) {
            throttle.recordFailure(0);
        }

        throttle.reset();

        expect(throttle.retryAfter(1)).toBe(0);
    });
});
