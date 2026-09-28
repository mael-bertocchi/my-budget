/**
 * @class ApiError
 * @description An error answered by the budget server, or raised while trying to reach it. Its message is written for
 * the person using the page.
 *
 * @extends Error
 */
export class ApiError extends Error {
    public status: number; /*!> The HTTP status, or 0 when the server could not be reached */

    /**
     * @constructor
     * @description Wraps a failed call
     *
     * @param {number} status The HTTP status, or 0 when the server could not be reached
     * @param {string} message The message to show
     */
    constructor(status: number, message: string) {
        super(message);

        this.status = status;
    }

    /**
     * @member isConflict
     * @description Whether the server refused a write because the budget moved on since it was read.
     */
    get isConflict(): boolean {
        return this.status === 409;
    }

    /**
     * @member isOffline
     * @description Whether the server could not be reached at all.
     */
    get isOffline(): boolean {
        return this.status === 0;
    }
}

/**
 * @function messageOf
 * @description The message to show for any error.
 *
 * @param {unknown} error The error.
 *
 * @returns {string} Its message.
 */
export function messageOf(error: unknown): string {
    return error instanceof Error ? error.message : 'Something went wrong.';
}
