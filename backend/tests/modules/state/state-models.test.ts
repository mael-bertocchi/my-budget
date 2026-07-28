import { CategorySchema, OperationSchema, SavingsMovementSchema, StateSchema } from 'src/modules/state/state-models';
import { describe, expect, it } from 'vitest';

const validCategory = {
    id: 'groceries',
    name: 'Groceries',
    symbol: 'cart',
    colorHex: 0x3ecf8e,
    monthlyLimit: 400,
    type: 'EXPENSE'
};

const validOperation = {
    id: '5f1b2c3d-4e5f-4a1b-8c2d-3e4f5a6b7c8d',
    date: '2026-07-24T18:00:00.000Z',
    name: 'Whole Foods',
    categoryId: 'groceries',
    location: 'Berlin Mitte',
    amount: 54.2,
    currencyCode: 'USD',
    rateToEuro: 0.9207,
    type: 'EXPENSE',
    isRecurring: false
};

describe('CategorySchema', () => {
    it('accepts a valid category', () => {
        expect(CategorySchema.safeParse(validCategory).success).toBe(true);
    });

    it('rejects a colour outside the 0xRRGGBB range', () => {
        expect(CategorySchema.safeParse({ ...validCategory, colorHex: 0x1000000 }).success).toBe(false);
    });

    it('rejects an unknown type', () => {
        expect(CategorySchema.safeParse({ ...validCategory, type: 'SAVINGS' }).success).toBe(false);
    });
});

describe('OperationSchema', () => {
    it('accepts an operation and coerces its date', () => {
        const parsed = OperationSchema.safeParse(validOperation);

        expect(parsed.success).toBe(true);
        expect(parsed.data?.date).toBeInstanceOf(Date);
    });

    it('accepts a null location', () => {
        expect(OperationSchema.safeParse({ ...validOperation, location: null }).success).toBe(true);
    });

    it('rejects a negative amount', () => {
        expect(OperationSchema.safeParse({ ...validOperation, amount: -1 }).success).toBe(false);
    });
});

describe('SavingsMovementSchema', () => {
    it('accepts a deposit without a goal', () => {
        const movement = { id: 'm1', date: '2026-07-01T00:00:00.000Z', name: 'Monthly deposit', amount: 300, kind: 'DEPOSIT' };

        expect(SavingsMovementSchema.safeParse(movement).success).toBe(true);
    });

    it('rejects an unknown kind', () => {
        const movement = { id: 'm1', date: '2026-07-01T00:00:00.000Z', name: 'x', amount: 300, kind: 'TRANSFER' };

        expect(SavingsMovementSchema.safeParse(movement).success).toBe(false);
    });
});

describe('StateSchema', () => {
    it('accepts a complete budget document', () => {
        const state = {
            categories: [validCategory],
            operations: [validOperation],
            goals: [{ id: 'japan', name: 'Japan trip', symbol: 'airplane', colorHex: 0x4d9bff, saved: 2150, target: 4000 }],
            movements: [{ id: 'm1', date: '2026-07-01T00:00:00.000Z', name: 'Monthly deposit', amount: 300, kind: 'DEPOSIT' }],
            savingsBalance: 11450,
            budget: { monthlyLimit: 3000 }
        };

        expect(StateSchema.safeParse(state).success).toBe(true);
    });

    it('rejects a document with a missing collection', () => {
        const state = {
            categories: [validCategory],
            operations: [validOperation],
            goals: [],
            savingsBalance: 0,
            budget: { monthlyLimit: 3000 }
        };

        expect(StateSchema.safeParse(state).success).toBe(false);
    });
});
