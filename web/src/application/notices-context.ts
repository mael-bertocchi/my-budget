import { createContext, useContext } from 'react';

/**
 * @interface Notices
 * @description Short messages shown at the bottom of the page.
 */
export interface Notices {
    notify: (message: string) => void; /*!< Shows a message for a few seconds */
}

/**
 * @constant NoticesContext
 * @description Hands the notices down the tree.
 */
export const NoticesContext = createContext<Notices | null>(null);

/**
 * @function useNotices
 * @description Shows short messages.
 */
export function useNotices(): Notices {
    const notices = useContext(NoticesContext);

    if (notices === null) {
        throw new Error('useNotices must be used inside NoticesProvider');
    }

    return notices;
}
