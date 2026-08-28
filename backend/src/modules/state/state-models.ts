import type { RequestGenericInterface } from 'fastify';
import { ColorSchema, IdSchema } from 'src/shared/schemas';
import { z } from 'zod';

/**
 * @constant MAX_ITEMS
 * @description Upper bound on the number of items of each kind accepted in a single state push.
 */
const MAX_ITEMS = 5000;

/**
 * @constant CategorySchema
 * @description Zod schema for one budget category.
 */
export const CategorySchema = z.object({
    id: IdSchema,
    name: z.string().min(1).max(60),
    symbol: z.string().min(1).max(60),
    colorHex: ColorSchema,
    monthlyLimit: z.number().min(0).max(1_000_000)
});

/**
 * @constant OperationSchema
 * @description Zod schema for one logged operation. The client-supplied `updatedAt` is accepted but the server owns the persisted value.
 */
export const OperationSchema = z.object({
    id: IdSchema,
    date: z.coerce.date(),
    name: z.string().min(1).max(120),
    description: z.string().max(500).nullish(),
    categoryId: IdSchema,
    location: z.string().max(200).nullish(),
    amount: z.number().min(0).max(1_000_000_000),
    currencyCode: z.string().min(1).max(8),
    rateToEuro: z.number().min(0).max(1_000_000),
    isOnline: z.boolean().default(false),
    isRecurring: z.boolean(),
    updatedAt: z.coerce.date().optional()
});

/**
 * @constant BudgetSettingsSchema
 * @description Zod schema for the overall monthly budget settings.
 */
export const BudgetSettingsSchema = z.object({
    monthlyLimit: z.number().min(0).max(1_000_000)
});

/**
 * @constant MonthlyBudgetSchema
 * @description Zod schema for the budget frozen against one finished month.
 */
export const MonthlyBudgetSchema = z.object({
    monthlyLimit: z.number().min(0).max(1_000_000),
    categoryLimits: z.record(IdSchema, z.number().min(0).max(1_000_000))
});

/**
 * @constant StateSchema
 * @description Zod schema for the whole budget document exchanged by the pull/push endpoints.
 */
export const StateSchema = z.object({
    categories: z.array(CategorySchema).max(MAX_ITEMS),
    operations: z.array(OperationSchema).max(MAX_ITEMS),
    budget: BudgetSettingsSchema,
    budgetHistory: z.record(z.string().regex(/^\d{4}-\d{2}$/), MonthlyBudgetSchema)
});

/**
 * @type StateBody
 * @description Inferred type for the full budget document.
 */
export type StateBody = z.infer<typeof StateSchema>;

/**
 * @interface StatePushRequest
 * @description Fastify request generic for the state-push endpoint.
 *
 * @extends RequestGenericInterface
 */
export interface StatePushRequest extends RequestGenericInterface {
    Body: StateBody; /*!< Validated full budget document */
}
