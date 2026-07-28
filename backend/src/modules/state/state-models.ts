import type { RequestGenericInterface } from 'fastify';
import { ColorSchema, IdSchema } from 'src/shared/schemas';
import { z } from 'zod';

/**
 * @constant MAX_ITEMS
 * @description Upper bound on the number of items of each kind accepted in a single state push.
 */
const MAX_ITEMS = 5000;

/**
 * @constant OperationTypeSchema
 * @description Zod schema for the expense/income discriminator.
 */
export const OperationTypeSchema = z.enum(['EXPENSE', 'INCOME']);

/**
 * @constant MovementKindSchema
 * @description Zod schema for the direction of a savings movement.
 */
export const MovementKindSchema = z.enum(['DEPOSIT', 'WITHDRAWAL']);

/**
 * @constant CategorySchema
 * @description Zod schema for one budget category.
 */
export const CategorySchema = z.object({
    id: IdSchema,
    name: z.string().min(1).max(60),
    symbol: z.string().min(1).max(60),
    colorHex: ColorSchema,
    monthlyLimit: z.number().min(0).max(1_000_000),
    type: OperationTypeSchema
});

/**
 * @constant OperationSchema
 * @description Zod schema for one logged operation. The client-supplied `updatedAt` is accepted but the server owns the persisted value.
 */
export const OperationSchema = z.object({
    id: IdSchema,
    date: z.coerce.date(),
    name: z.string().min(1).max(120),
    categoryId: IdSchema,
    location: z.string().max(200).nullish(),
    amount: z.number().min(0).max(1_000_000_000),
    currencyCode: z.string().min(1).max(8),
    rateToEuro: z.number().min(0).max(1_000_000),
    type: OperationTypeSchema,
    isRecurring: z.boolean(),
    updatedAt: z.coerce.date().optional()
});

/**
 * @constant SavingsGoalSchema
 * @description Zod schema for one savings goal.
 */
export const SavingsGoalSchema = z.object({
    id: IdSchema,
    name: z.string().min(1).max(60),
    symbol: z.string().min(1).max(60),
    colorHex: ColorSchema,
    saved: z.number().min(0).max(1_000_000_000),
    target: z.number().min(0).max(1_000_000_000)
});

/**
 * @constant SavingsMovementSchema
 * @description Zod schema for one deposit or withdrawal movement.
 */
export const SavingsMovementSchema = z.object({
    id: IdSchema,
    date: z.coerce.date(),
    name: z.string().min(1).max(120),
    note: z.string().max(200).nullish(),
    amount: z.number().min(0).max(1_000_000_000),
    kind: MovementKindSchema,
    goalId: IdSchema.nullish()
});

/**
 * @constant BudgetSettingsSchema
 * @description Zod schema for the overall monthly budget settings.
 */
export const BudgetSettingsSchema = z.object({
    monthlyLimit: z.number().min(0).max(1_000_000)
});

/**
 * @constant StateSchema
 * @description Zod schema for the whole budget document exchanged by the pull/push endpoints.
 */
export const StateSchema = z.object({
    categories: z.array(CategorySchema).max(MAX_ITEMS),
    operations: z.array(OperationSchema).max(MAX_ITEMS),
    goals: z.array(SavingsGoalSchema).max(MAX_ITEMS),
    movements: z.array(SavingsMovementSchema).max(MAX_ITEMS),
    savingsBalance: z.number().min(-1_000_000_000).max(1_000_000_000),
    budget: BudgetSettingsSchema
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
