import { createContext, useContext } from 'react';

/**
 * @type IdentityState
 * @description Whether the page is signed in.
 */
export type IdentityState = 'signedIn' | 'signedOut';

/**
 * @interface Session
 * @description Signing in and out.
 */
export interface Session {
    state: IdentityState; /*!< Whether the page is signed in */
    signIn: (code: string) => Promise<void>; /*!< Opens the budget with the six-digit code */
    signOut: () => Promise<void>; /*!< Closes the session */
}

/**
 * @constant SessionContext
 * @description Hands the session down the tree.
 */
export const SessionContext = createContext<Session | null>(null);

/**
 * @function useSession
 * @description Signing in and out.
 */
export function useSession(): Session {
    const session = useContext(SessionContext);

    if (session === null) {
        throw new Error('useSession must be used inside SessionProvider');
    }

    return session;
}
