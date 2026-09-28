import type { ApiClient } from '@core/api';
import { bankRate, EURO } from '@core/currencies';
import { dayKey } from '@core/dates';
import { messageOf } from '@core/errors';
import type { RateSnapshot } from '@core/models';
import type { Maybe } from '@/models';

/**
 * @class ExchangeRates
 * @description The reference rates the page prices foreign operations at: the latest ones for Settings, and those of
 * each day an operation is dated on. Every rate handed out carries the bank's markup, so a euro figure matches the
 * statement.
 */
export class ExchangeRates {
    private readonly api: ApiClient; /*!> The server */
    private latestSnapshot: Maybe<RateSnapshot> = null; /*!> The latest rates */
    private days = new Map<string, RateSnapshot>(); /*!> Rates by day */
    private failures = new Map<string, string>(); /*!> Why a day's rates are missing */
    private inFlight = new Map<string, Promise<void>>(); /*!> Day loads in progress */
    private listeners = new Set<() => void>(); /*!> Who to tell about new rates */
    private version = 0; /*!> Bumped on every change, for `useSyncExternalStore` */

    /**
     * @constructor
     * @description Prepares an empty cache
     *
     * @param {ApiClient} api The server
     */
    constructor(api: ApiClient) {
        this.api = api;
    }

    subscribe = (listener: () => void): (() => void) => {
        this.listeners.add(listener);

        return () => {
            this.listeners.delete(listener);
        };
    };

    getVersion = (): number => this.version;

    /**
     * @member latest
     * @description The latest rates, once loaded.
     */
    get latest(): Maybe<RateSnapshot> {
        return this.latestSnapshot;
    }

    /**
     * @function refreshLatest
     * @description Loads the latest rates. A failure keeps the previous ones.
     */
    async refreshLatest(): Promise<void> {
        try {
            this.latestSnapshot = await this.api.rates();
            this.changed();
        } catch {
            return;
        }
    }

    /**
     * @function load
     * @description Loads one day's rates, once. A day still answered by an earlier day's rate is loaded again later:
     * its own rate isn't published yet.
     *
     * @param {string} day The day, in YYYY-MM-DD form.
     */
    async load(day: string): Promise<void> {
        const cached = this.days.get(day);

        if (cached !== undefined && !(cached.quoteDate !== day && day >= dayKey(new Date()))) {
            return;
        }

        const running = this.inFlight.get(day);

        if (running !== undefined) {
            await running;
            return;
        }

        const task = (async () => {
            try {
                this.days.set(day, await this.api.ratesOn(day));
                this.failures.delete(day);
            } catch (error: unknown) {
                this.failures.set(day, messageOf(error));
            } finally {
                this.inFlight.delete(day);
                this.changed();
            }
        })();

        this.inFlight.set(day, task);
        await task;
    }

    /**
     * @function rate
     * @description The rate that applied to a currency on one day, markup included.
     *
     * @returns {Maybe<number>} Euros per unit, or null until that day is loaded.
     */
    rate(code: string, day: string): Maybe<number> {
        if (code === EURO.code) {
            return 1;
        }

        const published = this.days.get(day)?.rates[code];

        return published === undefined ? null : bankRate(published, code);
    }

    /**
     * @function failure
     * @description Why a day's rates are missing, or null when nothing went wrong.
     */
    failure(day: string): Maybe<string> {
        return this.failures.get(day) ?? null;
    }

    /**
     * @function changed
     * @description Tells the listeners.
     */
    private changed(): void {
        this.version += 1;

        for (const listener of this.listeners) {
            listener();
        }
    }
}
