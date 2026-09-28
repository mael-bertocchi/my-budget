import type { ApiClient } from '@core/api';
import { BudgetStore } from '@core/budget-store';
import { ApiError } from '@core/errors';
import type { BudgetDocument, StoredState } from '@core/models';
import { upsertOperation } from '@core/operations';
import { describe, expect, it, vi } from 'vitest';

import { document, NOW, operation } from '../support/fixtures';

/**
 * @function server
 * @description A fake server holding one budget, which refuses a write made from an old revision, can be made to take
 * a rival write before the next one lands, or to be unreachable.
 */
function server(initial: BudgetDocument) {
    const state = { stored: { ...initial, revision: 1 } as StoredState, rivals: [] as ((current: BudgetDocument) => BudgetDocument)[], offline: false, puts: 0 };
    const api = {
        getState: vi.fn(() => (state.offline ? Promise.reject(new ApiError(0, "Can't reach the server.")) : Promise.resolve(structuredClone(state.stored)))),
        putState: vi.fn((next: BudgetDocument, revision: number) => {
            if (state.offline) {
                return Promise.reject(new ApiError(0, "Can't reach the server."));
            }

            const rival = state.rivals.shift();

            if (rival !== undefined) {
                state.stored = { ...rival(state.stored), revision: state.stored.revision + 1 };
            }

            if (revision !== state.stored.revision) {
                return Promise.reject(new ApiError(409, 'The budget changed on the server since it was last read'));
            }

            state.puts += 1;
            state.stored = { ...structuredClone(next), revision: revision + 1 };

            return Promise.resolve(structuredClone(state.stored));
        })
    };

    return { state, api: api as unknown as ApiClient };
}

/**
 * @function settle
 * @description Lets the store's queued sends run.
 */
async function settle(): Promise<void> {
    for (let turn = 0; turn < 20; turn += 1) {
        await Promise.resolve();
    }
}

describe('BudgetStore', () => {
    it('shows an edit at once and stores it on top of the revision it read', async () => {
        const { state, api } = server(document());
        const store = new BudgetStore(api);

        await store.refresh();
        store.apply((current) => upsertOperation(current, operation({ id: 'A', date: NOW })));

        expect(store.getSnapshot().document?.operations).toHaveLength(1);
        await settle();
        expect(state.stored.revision).toBe(2);
        expect(store.getSnapshot()).toMatchObject({ status: 'synced', hasPendingChanges: false });
    });

    it('applies its edit again on top of what the app wrote in between, erasing nothing', async () => {
        const { state, api } = server(document());
        const store = new BudgetStore(api);

        await store.refresh();
        state.rivals.push((current) => upsertOperation(current, operation({ id: 'FROM-THE-APP', date: NOW })));
        store.apply((current) => upsertOperation(current, operation({ id: 'FROM-THE-WEB', date: NOW })));
        await settle();

        expect(state.stored.operations.map((entry) => entry.id).sort()).toEqual(['FROM-THE-APP', 'FROM-THE-WEB']);
        expect(store.getSnapshot().document?.operations).toHaveLength(2);
    });

    it('drops an edit that no longer applies and says so', async () => {
        const { api } = server(document());
        const store = new BudgetStore(api);
        const rejected = vi.fn();

        store.onRejected(rejected);
        await store.refresh();
        store.apply(() => {
            throw new Error('This operation was deleted on another device.');
        });
        await settle();

        expect(rejected).toHaveBeenCalledWith('This operation was deleted on another device.');
        expect(store.getSnapshot().hasPendingChanges).toBe(false);
    });

    it('keeps edits while offline and sends them once the server is back', async () => {
        const { state, api } = server(document());
        const store = new BudgetStore(api);

        await store.refresh();
        state.offline = true;
        store.apply((current) => ({ ...current, budget: { monthlyLimit: 2500 } }));
        await settle();

        expect(store.getSnapshot()).toMatchObject({ status: 'offline', hasPendingChanges: true });
        expect(store.getSnapshot().document?.budget.monthlyLimit).toBe(2500);

        state.offline = false;
        await store.refresh();

        expect(state.stored.budget.monthlyLimit).toBe(2500);
        expect(store.getSnapshot().status).toBe('synced');
        store.reset();
    });

    it('never rolls back to a read that a write overtook', async () => {
        const { state, api } = server(document());
        const store = new BudgetStore(api);
        const stale = structuredClone(state.stored);

        await store.refresh();
        store.apply((current) => ({ ...current, budget: { monthlyLimit: 1234 } }));
        await settle();
        vi.mocked(api.getState).mockResolvedValueOnce(stale);
        await store.refresh();

        expect(store.getSnapshot().document?.budget.monthlyLimit).toBe(1234);
    });
});
