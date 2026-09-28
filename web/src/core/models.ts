import { z } from 'zod';

/**
 * @constant CategorySchema
 * @description Zod schema for one budget category.
 */
export const CategorySchema = z.object({
    id: z.string(),
    name: z.string(),
    symbol: z.string(),
    colorHex: z.number().int(),
    monthlyLimit: z.number()
});

/**
 * @constant OperationSchema
 * @description Zod schema for one logged operation.
 */
export const OperationSchema = z.object({
    id: z.string(),
    date: z.coerce.date(),
    name: z.string(),
    description: z.string().nullish(),
    categoryId: z.string(),
    location: z.string().nullish(),
    amount: z.number(),
    currencyCode: z.string(),
    rateToEuro: z.number(),
    isOnline: z.boolean(),
    isRecurring: z.boolean(),
    updatedAt: z.coerce.date().optional()
});

/**
 * @constant MonthlyBudgetSchema
 * @description Zod schema for the budget frozen against one finished month.
 */
export const MonthlyBudgetSchema = z.object({
    monthlyLimit: z.number(),
    categoryLimits: z.record(z.string(), z.number())
});

/**
 * @constant BudgetDocumentSchema
 * @description Zod schema for the whole budget document, as the app and the backend exchange it.
 */
export const BudgetDocumentSchema = z.object({
    categories: z.array(CategorySchema),
    operations: z.array(OperationSchema),
    budget: z.object({ monthlyLimit: z.number() }),
    budgetHistory: z.record(z.string(), MonthlyBudgetSchema)
});

/**
 * @constant StoredStateSchema
 * @description Zod schema for the document as the backend stores it, with the revision a write has to name.
 */
export const StoredStateSchema = BudgetDocumentSchema.extend({
    revision: z.number().int()
});

/**
 * @constant RateSnapshotSchema
 * @description Zod schema for a set of reference rates: the euros one unit of each currency buys.
 */
export const RateSnapshotSchema = z.object({
    quoteDate: z.string(),
    fetchedAt: z.coerce.date(),
    rates: z.record(z.string(), z.number())
});

/**
 * @constant IdentityTokensSchema
 * @description Zod schema for an access/refresh token pair.
 */
export const IdentityTokensSchema = z.object({
    accessToken: z.string(),
    refreshToken: z.string()
});

export type Category = z.infer<typeof CategorySchema>;
export type Operation = z.infer<typeof OperationSchema>;
export type MonthlyBudget = z.infer<typeof MonthlyBudgetSchema>;
export type BudgetDocument = z.infer<typeof BudgetDocumentSchema>;
export type StoredState = z.infer<typeof StoredStateSchema>;
export type RateSnapshot = z.infer<typeof RateSnapshotSchema>;
export type IdentityTokens = z.infer<typeof IdentityTokensSchema>;
