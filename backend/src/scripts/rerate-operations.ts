import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

import { PrismaPg } from '@prisma/adapter-pg';
import 'dotenv/config';
import { PrismaClient } from 'prisma/generated/prisma/client';
import { fetchHistory, toIsoDay } from 'src/modules/rates/rates-history';
import { BASE_CURRENCY } from 'src/modules/rates/rates-models';
import type { RepricedOperation } from 'src/modules/rates/rates-reprice';
import { planReprice } from 'src/modules/rates/rates-reprice';

/**
 * @constant LEAD_DAYS
 * @description How far before the earliest operation to start the query, so a purchase made on a long
 * weekend still has a published day behind it to fall back to.
 */
const LEAD_DAYS = 10;

/**
 * @constant REPORT_DIRECTORY
 * @description Where the before/after record of each run is written. It doubles as the undo path.
 */
const REPORT_DIRECTORY = 'reports';

/**
 * @function report
 * @description Prints the run's findings as a table, then its totals.
 *
 * @param {RepricedOperation[]} changes The operations that would be rewritten.
 * @param {number} scanned How many foreign-currency operations were examined.
 */
function report(changes: RepricedOperation[], scanned: number): void {
    const oldTotal = changes.reduce((total, change) => total + change.oldEuro, 0);
    const newTotal = changes.reduce((total, change) => total + change.newEuro, 0);

    if (changes.length > 0) {
        console.log('\nDate         Currency        Amount   Stored rate   Actual rate         Booked      Correct     Delta');
        console.log('-'.repeat(105));

        for (const change of changes) {
            console.log([
                change.date.padEnd(11),
                change.currencyCode.padEnd(8),
                change.amount.toFixed(2).padStart(12),
                change.oldRate.toPrecision(6).padStart(13),
                change.newRate.toPrecision(6).padStart(13),
                `${change.oldEuro.toFixed(2)} EUR`.padStart(14),
                `${change.newEuro.toFixed(2)} EUR`.padStart(12),
                (change.newEuro - change.oldEuro).toFixed(2).padStart(9)
            ].join(' '));
        }
    }

    console.log(`\nScanned ${scanned} foreign-currency operations, ${changes.length} priced at the wrong rate.`);
    console.log(`Booked today: ${oldTotal.toFixed(2)} EUR — correctly: ${newTotal.toFixed(2)} EUR (${(newTotal - oldTotal).toFixed(2)} EUR).`);
}

/**
 * @function main
 * @description Re-prices every foreign-currency operation at the reference rate published on its own date.
 * Runs as a dry run unless `--apply` is passed.
 */
async function main(): Promise<void> {
    const apply = process.argv.includes('--apply');
    const connectionString = process.env.DATABASE_URL;

    if (connectionString === undefined || connectionString === '') {
        throw new Error('DATABASE_URL is not set');
    }

    const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString }) });

    try {
        const operations = await prisma.operation.findMany({ orderBy: { date: 'asc' } });
        const foreign = operations.filter((operation) => operation.currencyCode !== BASE_CURRENCY);
        const earliest = foreign.at(0);
        const newest = foreign.at(-1);

        if (earliest === undefined || newest === undefined) {
            console.log(`No operations in a currency other than ${BASE_CURRENCY}. Nothing to re-rate.`);

            return;
        }

        const start = new Date(earliest.date);
        start.setUTCDate(start.getUTCDate() - LEAD_DAYS);

        const history = await fetchHistory(
            toIsoDay(start),
            toIsoDay(new Date(Math.max(Date.now(), newest.date.getTime()))),
            foreign.map((operation) => operation.currencyCode)
        );

        const { scanned, changes, skipped } = planReprice(foreign, history);

        report(changes, scanned);

        if (skipped.length > 0) {
            console.warn(`\nNo published rate covered ${skipped.length} operation(s), left untouched:`);
            skipped.forEach((operation) => console.warn(`  ${toIsoDay(operation.date)} ${operation.currencyCode} ${operation.name}`));
        }

        if (changes.length === 0) {
            return;
        }

        await mkdir(REPORT_DIRECTORY, { recursive: true });

        const reportPath = path.join(REPORT_DIRECTORY, `rerate-${new Date().toISOString().replace(/[:.]/g, '-')}.json`);

        await writeFile(reportPath, `${JSON.stringify({ applied: apply, changes }, null, 4)}\n`, 'utf8');

        console.log(`\nWrote ${reportPath} — it holds every previous rate, so this run can be reversed.`);

        if (!apply) {
            console.log('Dry run: nothing was written to the database. Re-run with --apply to commit these changes.');

            return;
        }

        await prisma.$transaction(changes.map((change) => prisma.operation.update({
            where: { id: change.id },
            data: { rateToEuro: change.newRate }
        })));

        console.log(`Re-rated ${changes.length} operations.`);
    } finally {
        await prisma.$disconnect();
    }
}

try {
    await main();
} catch (error: unknown) {
    console.error(error instanceof Error ? error.message : error);
    process.exit(1);
}
