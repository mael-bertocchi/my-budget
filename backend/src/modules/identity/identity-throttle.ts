/**
 * @constant MAX_FAILURES
 * @description How many wrong codes are tolerated within the window before sign-in closes.
 */
export const MAX_FAILURES = 10;

/**
 * @constant FAILURE_WINDOW
 * @description The rolling window wrong codes are counted over.
 */
export const FAILURE_WINDOW = 15 * 60 * 1000;

/**
 * @class SignInThrottle
 * @description Caps wrong codes across every caller. A six-digit code has a million values, so a per-address rate
 * limit alone would let an attacker spread guesses over many addresses; this counts every failure, wherever it came
 * from, and closes sign-in once too many land within the window. At ten per quarter of an hour, going through half
 * the codes takes years. The account's owner stays signed in meanwhile: only new sign-ins wait.
 */
export class SignInThrottle {
    private failures: number[] = []; /*!> When each recent wrong code was submitted */

    /**
     * @function retryAfter
     * @description How long sign-in stays closed.
     *
     * @param {number} now The current time, in milliseconds.
     *
     * @returns {number} Milliseconds until a code is accepted again, 0 when it already is.
     */
    retryAfter(now: number = Date.now()): number {
        this.failures = this.failures.filter((failure) => now - failure < FAILURE_WINDOW);

        const [oldest] = this.failures;

        if (this.failures.length < MAX_FAILURES || oldest === undefined) {
            return 0;
        }

        return oldest + FAILURE_WINDOW - now;
    }

    /**
     * @function recordFailure
     * @description Counts a wrong code.
     *
     * @param {number} now The current time, in milliseconds.
     */
    recordFailure(now: number = Date.now()): void {
        this.failures.push(now);
    }

    /**
     * @function reset
     * @description Forgets the failures once the right code comes in.
     */
    reset(): void {
        this.failures = [];
    }
}
