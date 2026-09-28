import { useOperationEditor } from '@application/editor-context';
import { ChartPie, History as HistoryIcon, Plus, Settings, type LucideIcon } from 'lucide-react';
import type { JSX } from 'react';
import { Link, NavLink } from 'react-router-dom';

/**
 * @interface Tab
 * @description One of the app's tabs.
 */
interface Tab {
    to: string; /*!< Its path */
    label: string; /*!< Its name */
    icon: LucideIcon; /*!< Its icon on a phone's tab bar */
}

/**
 * @constant TABS
 * @description Budget, History and Settings, like the app's tab bar.
 */
const TABS: Tab[] = [
    { to: '/budget', label: 'Budget', icon: ChartPie },
    { to: '/history', label: 'History', icon: HistoryIcon },
    { to: '/settings', label: 'Settings', icon: Settings }
];

/**
 * @function NavigationComponent
 * @description A frosted bar with the tabs as a segmented control and the new operation button. On a phone the tabs
 * move to a tab bar along the bottom edge.
 */
function NavigationComponent(): JSX.Element {
    const { openNew } = useOperationEditor();

    return (
        <>
            <header className="sticky top-0 z-30 border-b border-hairline bg-white/75 pt-[env(safe-area-inset-top)] backdrop-blur-xl backdrop-saturate-150">
                <div className="mx-auto grid h-14 max-w-5xl grid-cols-[1fr_auto_1fr] items-center gap-4 px-5 sm:px-8">
                    <Link to="/budget" className="justify-self-start rounded-lg text-[17px] font-semibold tracking-tight">
                        My Budget
                    </Link>

                    <nav className="hidden rounded-full bg-fill p-1 sm:flex" aria-label="Sections">
                        {TABS.map(({ to, label }) => (
                            <NavLink
                                key={to}
                                to={to}
                                className={({ isActive }) => `rounded-full px-4 py-1.5 text-[14px] font-medium transition ${isActive ? 'bg-white text-ink shadow-control' : 'text-ink-secondary hover:text-ink'}`}
                            >
                                {label}
                            </NavLink>
                        ))}
                    </nav>

                    <button
                        type="button"
                        onClick={openNew}
                        className="col-start-3 flex h-9 items-center gap-1.5 justify-self-end rounded-full bg-accent pl-2.5 pr-2.5 text-[14px] font-semibold text-white transition hover:bg-accent-strong active:scale-95 sm:pl-3 sm:pr-4"
                        aria-label="New operation"
                    >
                        <Plus size={18} strokeWidth={2.6} />
                        <span className="hidden sm:inline">New operation</span>
                    </button>
                </div>
            </header>

            <nav className="fixed inset-x-0 bottom-0 z-30 grid grid-cols-3 border-t border-hairline bg-white/80 pb-[env(safe-area-inset-bottom)] backdrop-blur-xl backdrop-saturate-150 sm:hidden" aria-label="Sections">
                {TABS.map(({ to, label, icon: Icon }) => (
                    <NavLink key={to} to={to} className={({ isActive }) => `flex flex-col items-center gap-0.5 pb-1.5 pt-2 text-[11px] font-medium ${isActive ? 'text-accent' : 'text-ink-tertiary'}`}>
                        <Icon size={23} strokeWidth={2} />
                        {label}
                    </NavLink>
                ))}
            </nav>
        </>
    );
}

export default NavigationComponent;
