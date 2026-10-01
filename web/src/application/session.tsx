import { useNotices } from '@application/notices-context';
import type { Services } from '@application/services';
import { createServices, ServicesContext } from '@application/services';
import type { IdentityState, Session } from '@application/session-context';
import { SessionContext } from '@application/session-context';
import { repriceRecent } from '@core/reprice';
import { useCallback, useEffect, useMemo, useState, type JSX, type ReactNode } from 'react';

/**
 * @constant CATCH_UP_EVERY
 * @description How often an open page reads the budget again, to show what the app wrote in the meantime.
 */
const CATCH_UP_EVERY = 60 * 1000;

/**
 * @function useCatchUp
 * @description Keeps a signed-in page in step with the server: it reads the budget when the page opens, when it comes
 * back into view, when the connection returns and every minute while visible: the web version of the app reconciling
 * when it becomes active. The first read also re-prices recent foreign operations, as the app does.
 */
function useCatchUp(services: Services, state: IdentityState): void {
    useEffect(() => {
        if (state !== 'signedIn') {
            return;
        }

        const { store, rates } = services;
        let hasRepriced = false;

        const catchUp = async (): Promise<void> => {
            await store.refresh();

            const current = store.getSnapshot().document;

            if (!hasRepriced && current !== null) {
                hasRepriced = true;

                const correction = await repriceRecent(current, rates);

                if (correction !== null) {
                    store.apply(correction);
                }
            }
        };

        const whenVisible = (): void => {
            if (window.document.visibilityState === 'visible') {
                void catchUp();
            }
        };

        const warnBeforeLeaving = (event: BeforeUnloadEvent): void => {
            if (store.getSnapshot().hasPendingChanges) {
                event.preventDefault();
            }
        };

        void catchUp();
        void rates.refreshLatest();

        const interval = window.setInterval(whenVisible, CATCH_UP_EVERY);

        window.addEventListener('focus', whenVisible);
        window.addEventListener('online', whenVisible);
        window.addEventListener('beforeunload', warnBeforeLeaving);
        window.document.addEventListener('visibilitychange', whenVisible);

        return () => {
            window.clearInterval(interval);
            window.removeEventListener('focus', whenVisible);
            window.removeEventListener('online', whenVisible);
            window.removeEventListener('beforeunload', warnBeforeLeaving);
            window.document.removeEventListener('visibilitychange', whenVisible);
        };
    }, [services, state]);
}

/**
 * @function SessionProvider
 * @description Owns the page's services and its signed-in state.
 */
function SessionProvider({ children }: { children: ReactNode }): JSX.Element {
    const [services] = useState<Services>(createServices);
    const [state, setState] = useState<IdentityState>(services.api.isSignedIn ? 'signedIn' : 'signedOut');
    const { notify } = useNotices();

    useEffect(() => services.api.onSessionEnded(() => {
        services.store.reset();
        setState('signedOut');
    }), [services]);

    useEffect(() => services.store.onRejected(notify), [services, notify]);

    useCatchUp(services, state);

    const signIn = useCallback(async (code: string): Promise<void> => {
        await services.api.login(code);
        setState('signedIn');
    }, [services]);

    const signOut = useCallback(async (): Promise<void> => {
        await services.api.logout();
        services.store.reset();
        setState('signedOut');
    }, [services]);

    const session = useMemo<Session>(() => ({ state, signIn, signOut }), [state, signIn, signOut]);

    return (
        <ServicesContext.Provider value={services}>
            <SessionContext.Provider value={session}>
                {children}
            </SessionContext.Provider>
        </ServicesContext.Provider>
    );
}

export default SessionProvider;
