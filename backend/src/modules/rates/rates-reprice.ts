import type { RateHistory } from 'src/modules/rates/rates-history';
import { resolveRate, toIsoDay } from 'src/modules/rates/rates-history';
import { BASE_CURRENCY } from 'src/modules/rates/rates-models';

/**
 * @constant EPSILON
 * @description How far a stored rate may sit from the historical one before it counts as worth rewriting.
 */
const EPSILON = 1e-9;

/**
 * @interface RepriceableOperation
 * @description The parts of a stored operation this pass needs to judge its rate.
 */
export interface RepriceableOperation {
    id: string; /*!< The operation's identifier */
    date: Date; /*!< The day the operation happened on */
    name: string; /*!< The operation's label */
    amount: number; /*!< The amount in its own currency */
    currencyCode: string; /*!< The currency it was paid in */
    rateToEuro: number; /*!< The rate currently stored against it */
}

/**
 * @interface RepricedOperation
 * @description One operation whose stored rate disagrees with the rate published on its own date.
 */
export interface RepricedOperation {
    id: string; /*!< The operation's identifier */
    date: string; /*!< The day the operation happened on */
    name: string; /*!< The operation's label, for the printed report */
    currencyCode: string; /*!< The currency it was paid in */
    amount: number; /*!< The amount in that currency */
    oldRate: number; /*!< The rate currently stored against it */
    newRate: number; /*!< The rate published on its date */
    oldEuro: number; /*!< What it books as today, in euros */
    newEuro: number; /*!< What it will book as, in euros */
}

/**
 * @interface RepricePlan
 * @description Everything a re-rate pass decided, before any of it is written.
 */
export interface RepricePlan {
    scanned: number; /*!< How many foreign-currency operations were examined */
    changes: RepricedOperation[]; /*!< The operations priced at the wrong rate */
    skipped: RepriceableOperation[]; /*!< Operations no published rate covered */
}

/**
 * @function planReprice
 * @description Works out which operations are priced at the wrong rate, without touching any of them.
 * Operations already in the base currency are left alone, as are those whose stored rate already matches
 * the rate published on their date, which is what makes the pass safe to re-run.
 *
 * @param {RepriceableOperation[]} operations Every stored operation.
 * @param {RateHistory} history The published quotes to price against.
 *
 * @returns {RepricePlan} The operations to rewrite, and those nothing covered.
 */
export function planReprice(operations: RepriceableOperation[], history: RateHistory): RepricePlan {
    const foreign = operations.filter((operation) => operation.currencyCode !== BASE_CURRENCY);
    const changes: RepricedOperation[] = [];
    const skipped: RepriceableOperation[] = [];

    for (const operation of foreign) {
        const rate = resolveRate(history, operation.date, operation.currencyCode);

        if (rate === null) {
            skipped.push(operation);

            continue;
        }

        if (Math.abs(rate - operation.rateToEuro) <= EPSILON) {
            continue;
        }

        changes.push({
            id: operation.id,
            date: toIsoDay(operation.date),
            name: operation.name,
            currencyCode: operation.currencyCode,
            amount: operation.amount,
            oldRate: operation.rateToEuro,
            newRate: rate,
            oldEuro: operation.amount * operation.rateToEuro,
            newEuro: operation.amount * rate
        });
    }

    return { scanned: foreign.length, changes, skipped };
}
