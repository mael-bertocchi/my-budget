import type { Currency } from '@core/currencies';
import { EURO } from '@core/currencies';
import { isSameDay } from '@core/dates';

/**
 * @constant MONTHS
 * @description Month names, in English like the app.
 */
const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/**
 * @constant WEEKDAYS
 * @description Abbreviated weekday names, Sunday first like `Date.getDay`.
 */
const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/**
 * @constant compact
 * @description Whole amounts with thousands separators: 1,234.
 */
const compact = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });

/**
 * @constant precise
 * @description Amounts to the cent with thousands separators: 1,234.50.
 */
const precise = new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

/**
 * @constant significant
 * @description Rates to five significant digits. They span orders of magnitude — a euro buys about one dollar but
 * over fifteen hundred won — so a fixed count of decimals would flatten the small ones.
 */
const significant = new Intl.NumberFormat('en-US', { minimumSignificantDigits: 5, maximumSignificantDigits: 5, useGrouping: false });

/**
 * @function roundHalfAwayFromZero
 * @description Rounds like Swift's `rounded()`, so a figure lands on the same euro in the app and on the web.
 */
function roundHalfAwayFromZero(value: number): number {
    return Math.sign(value) * Math.round(Math.abs(value)) || 0;
}

/**
 * @function euro
 * @description A euro amount rounded to the euro: €1,234.
 */
export function euro(amount: number): string {
    return `€${compact.format(roundHalfAwayFromZero(amount))}`;
}

/**
 * @function euroPrecise
 * @description A euro amount to the cent: €1,234.50.
 */
export function euroPrecise(amount: number): string {
    return `€${precise.format(amount)}`;
}

/**
 * @function money
 * @description An amount in its own currency, to the cent and without a sign: $48.90.
 */
export function money(amount: number, currency: Currency = EURO): string {
    return `${currency.symbol}${precise.format(Math.abs(amount))}`;
}

/**
 * @function rate
 * @description An exchange rate to five significant digits: 0.86903.
 */
export function rate(value: number): string {
    return significant.format(value);
}

/**
 * @function percent
 * @description A fraction as a whole percentage: 58%.
 */
export function percent(fraction: number): string {
    return `${Math.round(fraction * 100)}%`;
}

/**
 * @function monthTitle
 * @description A month's name: September.
 */
export function monthTitle(date: Date): string {
    return MONTHS[date.getMonth()] ?? '';
}

/**
 * @function monthWithYear
 * @description A month and its year: September 2026.
 */
export function monthWithYear(date: Date): string {
    return `${monthTitle(date)} ${date.getFullYear()}`;
}

/**
 * @function dayShort
 * @description A day and abbreviated month: 27 Sep.
 */
export function dayShort(date: Date): string {
    return `${date.getDate()} ${monthTitle(date).slice(0, 3)}`;
}

/**
 * @function weekdayDay
 * @description A weekday, day and month: Sat 27 Sep.
 */
export function weekdayDay(date: Date): string {
    return `${WEEKDAYS[date.getDay()] ?? ''} ${dayShort(date)}`;
}

/**
 * @function relativeDay
 * @description Today, Yesterday, or the weekday and date, the way History labels its day groups.
 */
export function relativeDay(date: Date, now: Date = new Date()): string {
    if (isSameDay(date, now)) {
        return 'Today';
    }

    if (isSameDay(date, new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1))) {
        return 'Yesterday';
    }

    return weekdayDay(date);
}

/**
 * @function fieldDate
 * @description The date of an operation the way its editor shows it: Today, 27 Sep.
 */
export function fieldDate(date: Date, now: Date = new Date()): string {
    const relative = relativeDay(date, now);

    return relative === 'Today' || relative === 'Yesterday' ? `${relative}, ${dayShort(date)}` : relative;
}

/**
 * @function amountInput
 * @description An amount the way it is prefilled in a form: 12 or 12.50, never grouped.
 */
export function amountInput(amount: number): string {
    return Number.isInteger(amount) ? String(amount) : amount.toFixed(2);
}

/**
 * @function truncate
 * @description Shortens text to a length, ending it with an ellipsis when cut.
 */
export function truncate(text: string, length: number): string {
    return text.length <= length ? text : `${text.slice(0, Math.max(0, length - 1))}…`;
}
