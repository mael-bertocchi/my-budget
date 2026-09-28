import type { Notices } from '@application/notices-context';
import { NoticesContext } from '@application/notices-context';
import { useCallback, useMemo, useRef, useState, type JSX, type ReactNode } from 'react';

/**
 * @constant SHOWN_FOR
 * @description How long a message stays.
 */
const SHOWN_FOR = 4500;

/**
 * @function NoticesProvider
 * @description Shows one message at a time in a pill at the bottom of the page.
 */
function NoticesProvider({ children }: { children: ReactNode }): JSX.Element {
    const [message, setMessage] = useState<string | null>(null);
    const timer = useRef<number | undefined>(undefined);

    const notify = useCallback((text: string): void => {
        window.clearTimeout(timer.current);
        setMessage(text);
        timer.current = window.setTimeout(() => setMessage(null), SHOWN_FOR);
    }, []);

    const notices = useMemo<Notices>(() => ({ notify }), [notify]);

    return (
        <NoticesContext.Provider value={notices}>
            {children}
            <div aria-live="polite" className="pointer-events-none fixed inset-x-0 bottom-24 z-50 flex justify-center px-5 sm:bottom-8">
                {message !== null && (
                    <p className="animate-rise rounded-full bg-ink/90 px-5 py-3 text-[14px] font-medium text-white shadow-sheet backdrop-blur-xl">
                        {message}
                    </p>
                )}
            </div>
        </NoticesContext.Provider>
    );
}

export default NoticesProvider;
