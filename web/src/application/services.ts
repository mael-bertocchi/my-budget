import { ApiClient } from '@core/api';
import { BudgetStore } from '@core/budget-store';
import { ExchangeRates } from '@core/exchange-rates';
import { createContext, useContext } from 'react';

/**
 * @interface Services
 * @description The long-lived objects the page shares: the server, the budget and the rates.
 */
export interface Services {
    api: ApiClient; /*!< The server */
    store: BudgetStore; /*!< The budget */
    rates: ExchangeRates; /*!< The exchange rates */
}

/**
 * @function createServices
 * @description Builds the services once for the page's lifetime.
 */
export function createServices(): Services {
    const api = new ApiClient();

    return { api, store: new BudgetStore(api), rates: new ExchangeRates(api) };
}

/**
 * @constant ServicesContext
 * @description Hands the services down the tree.
 */
export const ServicesContext = createContext<Services | null>(null);

/**
 * @function useServices
 * @description The page's services.
 */
export function useServices(): Services {
    const services = useContext(ServicesContext);

    if (services === null) {
        throw new Error('useServices must be used inside SessionProvider');
    }

    return services;
}
