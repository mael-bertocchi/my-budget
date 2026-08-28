import type { PrismaClient } from 'prisma/generated/prisma/client';
import type { StateBody } from 'src/modules/state/state-models';
import { OWNER_ID } from 'src/plugins/identity';

/**
 * @constant DEFAULT_MONTHLY_LIMIT
 * @description The monthly budget assumed before the client has ever pushed its settings.
 */
const DEFAULT_MONTHLY_LIMIT = 3000;

/**
 * @function pullState
 * @description Reads the whole budget document back for the owner, in the order the client expects to render it.
 *
 * @param {PrismaClient} prisma The database client.
 *
 * @returns {Promise<StateBody>} The full budget document.
 */
export async function pullState(prisma: PrismaClient): Promise<StateBody> {
    const [categories, operations, state] = await Promise.all([
        prisma.category.findMany({ orderBy: { position: 'asc' } }),
        prisma.operation.findMany({ orderBy: { date: 'desc' } }),
        prisma.budgetState.findUnique({ where: { id: OWNER_ID } })
    ]);

    return {
        categories: categories.map((category) => ({
            id: category.id,
            name: category.name,
            symbol: category.symbol,
            colorHex: category.colorHex,
            monthlyLimit: category.monthlyLimit
        })),
        operations: operations.map((operation) => ({
            id: operation.id,
            date: operation.date,
            name: operation.name,
            categoryId: operation.categoryId,
            location: operation.location,
            amount: operation.amount,
            currencyCode: operation.currencyCode,
            rateToEuro: operation.rateToEuro,
            isRecurring: operation.isRecurring,
            updatedAt: operation.updatedAt
        })),
        budget: { monthlyLimit: state?.monthlyLimit ?? DEFAULT_MONTHLY_LIMIT }
    };
}

/**
 * @function pushState
 * @description Replaces the owner's whole budget document with the pushed one inside a single transaction, then returns the persisted result.
 *
 * @param {PrismaClient} prisma The database client.
 * @param {StateBody} body The full budget document to store.
 *
 * @returns {Promise<StateBody>} The stored budget document, read back after the write.
 */
export async function pushState(prisma: PrismaClient, body: StateBody): Promise<StateBody> {
    await prisma.$transaction([
        prisma.category.deleteMany(),
        prisma.operation.deleteMany(),
        prisma.category.createMany({
            data: body.categories.map((category, index) => ({
                id: category.id,
                name: category.name,
                symbol: category.symbol,
                colorHex: category.colorHex,
                monthlyLimit: category.monthlyLimit,
                position: index
            }))
        }),
        prisma.operation.createMany({
            data: body.operations.map((operation) => ({
                id: operation.id,
                date: operation.date,
                name: operation.name,
                categoryId: operation.categoryId,
                location: operation.location ?? null,
                amount: operation.amount,
                currencyCode: operation.currencyCode,
                rateToEuro: operation.rateToEuro,
                isRecurring: operation.isRecurring
            }))
        }),
        prisma.budgetState.upsert({
            where: { id: OWNER_ID },
            update: { monthlyLimit: body.budget.monthlyLimit },
            create: { id: OWNER_ID, monthlyLimit: body.budget.monthlyLimit }
        })
    ]);

    return await pullState(prisma);
}
