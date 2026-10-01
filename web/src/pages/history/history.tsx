import { useOperationEditor } from '@application/editor-context';
import { useDocument } from '@application/hooks';
import EmptyStateComponent from '@components/empty-state';
import { CategoryIconComponent } from '@components/icon-tile';
import { dayGroups, euroAmount } from '@core/budget-math';
import { categoriesOf, categoryName, categoryOrFallback } from '@core/categories';
import { currencyNamed, EURO } from '@core/currencies';
import { euroPrecise, money, relativeDay } from '@core/formatting';
import { t } from '@core/i18n';
import type { BudgetDocument, Operation } from '@core/models';
import { AlignLeft, Globe, MapPin, Repeat, Search, X } from 'lucide-react';
import { useMemo, type JSX } from 'react';
import { useSearchParams } from 'react-router-dom';

/**
 * @function matches
 * @description Whether an operation matches a search, by name, note, place or category, as the app searches.
 */
function matches(document: BudgetDocument, operation: Operation, query: string): boolean {
    const needle = query.trim().toLowerCase();

    if (needle === '') {
        return true;
    }

    const haystack = [operation.name, operation.description, operation.location, categoryName(categoryOrFallback(document.categories, operation.categoryId))];

    return haystack.some((text) => (text ?? '').toLowerCase().includes(needle));
}

/**
 * @function OperationRow
 * @description One operation: its category, name and marks, where it happened, and its amount — with the euro figure
 * under a foreign one.
 */
function OperationRow({ document, operation, onOpen }: { document: BudgetDocument; operation: Operation; onOpen: () => void }): JSX.Element {
    const category = categoryOrFallback(document.categories, operation.categoryId);
    const isForeign = operation.currencyCode !== EURO.code;
    const hasDescription = (operation.description ?? '') !== '';

    return (
        <button type="button" onClick={onOpen} className="flex w-full items-center gap-3.5 px-4 py-3.5 text-left transition hover:bg-fill/60 sm:px-5">
            <CategoryIconComponent category={category} size={40} />
            <span className="min-w-0 flex-1">
                <span className="flex items-center gap-1.5">
                    <span className="truncate text-[15px] font-medium">{operation.name}</span>
                    {operation.isRecurring && <Repeat size={13} className="shrink-0 text-ink-quaternary" aria-label={t('history.recurring')} />}
                    {hasDescription && <AlignLeft size={13} className="shrink-0 text-ink-quaternary" aria-label={t('history.hasNote')} />}
                </span>
                {operation.isOnline && (
                    <span className="mt-0.5 flex items-center gap-1 text-[13px] text-ink-secondary"><Globe size={12} /> {t('history.online')}</span>
                )}
                {!operation.isOnline && (operation.location ?? '') !== '' && (
                    <span className="mt-0.5 flex items-center gap-1 text-[13px] text-ink-secondary"><MapPin size={12} className="shrink-0" /> <span className="truncate">{operation.location}</span></span>
                )}
            </span>
            <span className="shrink-0 text-right">
                <span className="block text-[15px] font-semibold tabular-nums">{money(operation.amount, currencyNamed(operation.currencyCode))}</span>
                {isForeign && <span className="block text-[12px] text-ink-tertiary tabular-nums">{euroPrecise(euroAmount(operation))}</span>}
            </span>
        </button>
    );
}

/**
 * @function HistoryPage
 * @description The History tab: every operation grouped by day with each day's total, a search and one filter chip per
 * category. The filters live in the address, so a category opened from Budget survives a reload.
 */
function HistoryPage(): JSX.Element {
    const document = useDocument();
    const { openEdit } = useOperationEditor();
    const [params, setParams] = useSearchParams();
    const query = params.get('q') ?? '';
    const categoryId = params.get('category');

    const groups = useMemo(() => dayGroups(document.operations.filter((operation) =>
        (categoryId === null || operation.categoryId === categoryId) && matches(document, operation, query))), [document, categoryId, query]);

    /**
     * @function update
     * @description Changes one filter in the address.
     */
    const update = (key: string, value: string | null): void => {
        const next = new URLSearchParams(params);

        if (value === null || value === '') {
            next.delete(key);
        } else {
            next.set(key, value);
        }

        setParams(next, { replace: true });
    };

    const isFiltered = query !== '' || categoryId !== null;
    const chips = [{ id: null, name: t('history.all') }, ...categoriesOf(document.categories).map((category) => ({ id: category.id, name: categoryName(category) }))];

    return (
        <div className="mx-auto max-w-3xl animate-rise">
            <p className="eyebrow">{t('history.eyebrow')}</p>
            <h1 className="mt-1 text-[34px] font-semibold leading-tight tracking-tight">{t('history.title')}</h1>

            <label className="relative mt-6 block">
                <Search size={17} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-ink-tertiary" />
                <input
                    type="search"
                    value={query}
                    onChange={(event) => update('q', event.target.value)}
                    placeholder={t('history.search')}
                    className="h-11 w-full rounded-xl bg-fill-strong/70 pl-10 pr-10 text-[16px] outline-none transition placeholder:text-ink-tertiary focus:bg-white focus:shadow-control focus:ring-2 focus:ring-accent/40 [&::-webkit-search-cancel-button]:hidden"
                />
                {query !== '' && (
                    <button type="button" aria-label={t('history.clearSearch')} onClick={() => update('q', null)} className="absolute right-3 top-1/2 flex h-5 w-5 -translate-y-1/2 items-center justify-center rounded-full bg-ink-quaternary text-white">
                        <X size={12} strokeWidth={3} />
                    </button>
                )}
            </label>

            <div className="no-scrollbar -mx-5 mt-4 flex gap-2 overflow-x-auto px-5 sm:mx-0 sm:flex-wrap sm:overflow-visible sm:px-0">
                {chips.map((chip) => {
                    const isActive = chip.id === categoryId;

                    return (
                        <button
                            key={chip.id ?? 'all'}
                            type="button"
                            onClick={() => update('category', isActive ? null : chip.id)}
                            className={`h-8 shrink-0 rounded-full px-3.5 text-[14px] font-medium transition ${isActive ? 'bg-ink text-white' : 'bg-white text-ink shadow-control hover:bg-fill'}`}
                        >
                            {chip.name}
                        </button>
                    );
                })}
            </div>

            <div className="mt-2">
                {groups.length === 0 && (
                    <div className="mt-6">
                        <EmptyStateComponent message={isFiltered ? t('history.noMatch') : t('history.empty')} />
                    </div>
                )}
                {groups.map((group) => (
                    <section key={group.date.getTime()}>
                        <div className="flex items-baseline justify-between px-1 pb-2 pt-7">
                            <h2 className="eyebrow">{relativeDay(group.date)}</h2>
                            <span className="text-[13px] text-ink-tertiary tabular-nums">{money(group.spent)}</span>
                        </div>
                        <div className="card divide-y divide-hairline overflow-hidden">
                            {group.operations.map((operation) => (
                                <OperationRow key={operation.id} document={document} operation={operation} onOpen={() => openEdit(operation.id)} />
                            ))}
                        </div>
                    </section>
                ))}
            </div>
        </div>
    );
}

export default HistoryPage;
