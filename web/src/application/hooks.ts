import { useServices } from '@application/services';
import type { BudgetSnapshot } from '@core/budget-store';
import type { ExchangeRates } from '@core/exchange-rates';
import type { Language } from '@core/i18n';
import { currentLanguage, subscribeLanguage } from '@core/i18n';
import type { BudgetDocument } from '@core/models';
import { useSyncExternalStore } from 'react';

/**
 * @function useBudget
 * @description The budget as the page renders it, with where it stands with the server.
 */
export function useBudget(): BudgetSnapshot {
    const { store } = useServices();

    return useSyncExternalStore(store.subscribe, store.getSnapshot);
}

/**
 * @function useDocument
 * @description The budget itself. Only used under the layout, which waits for the first read before rendering a page.
 */
export function useDocument(): BudgetDocument {
    const { document } = useBudget();

    if (document === null) {
        throw new Error('useDocument must be used once the budget is loaded');
    }

    return document;
}

/**
 * @function useLanguage
 * @description The language the page is in, re-rendering whenever another is picked.
 */
export function useLanguage(): Language {
    return useSyncExternalStore(subscribeLanguage, currentLanguage);
}

/**
 * @function useRates
 * @description The exchange rates, re-rendering whenever new ones arrive.
 */
export function useRates(): ExchangeRates {
    const { rates } = useServices();

    useSyncExternalStore(rates.subscribe, rates.getVersion);

    return rates;
}
