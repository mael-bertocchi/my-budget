import { EURO } from '@core/currencies';
import { wholeSeconds } from '@core/dates';
import type { BudgetDocument, Operation } from '@core/models';
import type { Maybe } from '@/models';

/**
 * @constant MAX_DIGITS
 * @description How many digits an amount can hold, cents included, like the app's amount field.
 */
const MAX_DIGITS = 8;

/**
 * @constant Limits
 * @description The longest texts the server stores.
 */
export const Limits = {
    name: 120,
    description: 500,
    location: 200
};

/**
 * @interface OperationDraft
 * @description What the operation editor holds before it is saved.
 */
export interface OperationDraft {
    name: string; /*!< What it was */
    description: string; /*!< An optional note */
    amount: number; /*!< How much, in its own currency */
    currencyCode: string; /*!< The currency it was paid in */
    categoryId: string; /*!< Where it is filed */
    date: Date; /*!< When it happened */
    location: string; /*!< Where it happened, ignored when online */
    isOnline: boolean; /*!< Whether it has no physical location */
    isRecurring: boolean; /*!< Whether it repeats monthly */
}

/**
 * @function sanitizeAmountInput
 * @description Keeps what is typed in the amount field a valid amount: digits, one decimal separator, two decimals at
 * most and eight digits in all. A comma followed by at most two digits is read as the decimal separator, so 12,50 works.
 *
 * @param {string} text What was typed.
 *
 * @returns {string} The cleaned amount, with a dot as separator and no grouping.
 */
export function sanitizeAmountInput(text: string): string {
    let working = text;

    if (!working.includes('.') && /^[^,]*,\d{0,2}$/.test(working)) {
        working = working.replace(',', '.');
    }

    working = working.replaceAll(',', '');

    let integer = '';
    let fraction = '';
    let hasSeparator = false;
    let digits = 0;

    for (const character of working) {
        if (/\d/.test(character)) {
            if (digits >= MAX_DIGITS || (hasSeparator && fraction.length >= 2)) {
                continue;
            }

            if (hasSeparator) {
                fraction += character;
            } else {
                integer += character;
            }

            digits += 1;
        } else if (character === '.' && !hasSeparator) {
            hasSeparator = true;
        }
    }

    integer = integer.replace(/^0+(?=\d)/, '');

    if (integer === '') {
        if (!hasSeparator) {
            return '';
        }

        integer = '0';
    }

    return hasSeparator ? `${integer}.${fraction}` : integer;
}

/**
 * @function groupAmountInput
 * @description Adds thousands separators to a cleaned amount, as the app does while typing.
 */
export function groupAmountInput(cleaned: string): string {
    const [integer = '', ...fraction] = cleaned.split('.');
    const grouped = integer.replace(/\B(?=(\d{3})+(?!\d))/g, ',');

    return fraction.length > 0 ? `${grouped}.${fraction.join('')}` : grouped;
}

/**
 * @function parseAmountInput
 * @description Reads the amount field.
 *
 * @returns {Maybe<number>} The amount, or null when nothing above zero is typed.
 */
export function parseAmountInput(text: string): Maybe<number> {
    const amount = Number(sanitizeAmountInput(text));

    return Number.isFinite(amount) && amount > 0 ? amount : null;
}

/**
 * @function amountInputOf
 * @description An amount the way the field shows it: 12 or 12.50, grouped.
 */
export function amountInputOf(amount: number): string {
    return groupAmountInput(Number.isInteger(amount) ? String(amount) : amount.toFixed(2));
}

/**
 * @function toOperation
 * @description Builds the operation a draft describes. An online operation has no place; empty texts are stored as none.
 *
 * @param {OperationDraft} draft The editor's content.
 * @param {number} rateToEuro The rate to price it at.
 * @param {string} id The id to keep, or none to mint one in the app's uppercase UUID form.
 *
 * @returns {Operation} The operation.
 */
export function toOperation(draft: OperationDraft, rateToEuro: number, id?: string): Operation {
    const description = draft.description.trim();
    const location = draft.isOnline ? '' : draft.location.trim();

    return {
        id: id ?? crypto.randomUUID().toUpperCase(),
        date: wholeSeconds(draft.date),
        name: draft.name.trim(),
        description: description === '' ? null : description,
        categoryId: draft.categoryId,
        location: location === '' ? null : location,
        amount: draft.amount,
        currencyCode: draft.currencyCode,
        rateToEuro: draft.currencyCode === EURO.code ? 1 : rateToEuro,
        isOnline: draft.isOnline,
        isRecurring: draft.isRecurring,
        updatedAt: new Date()
    };
}

/**
 * @function upsertOperation
 * @description Adds an operation, or replaces the one with its id.
 */
export function upsertOperation(document: BudgetDocument, operation: Operation): BudgetDocument {
    const exists = document.operations.some((candidate) => candidate.id === operation.id);

    return {
        ...document,
        operations: exists
            ? document.operations.map((candidate) => (candidate.id === operation.id ? operation : candidate))
            : [...document.operations, operation]
    };
}

/**
 * @function deleteOperation
 * @description Removes an operation.
 */
export function deleteOperation(document: BudgetDocument, id: string): BudgetDocument {
    return { ...document, operations: document.operations.filter((operation) => operation.id !== id) };
}
