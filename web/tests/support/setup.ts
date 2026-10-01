import { beforeEach } from 'vitest';

/**
 * @function memoryStorage
 * @description A Web Storage kept in memory. Node only offers `localStorage` behind a flag and warns each time it is
 * touched, while the page reads it as soon as the language module loads.
 */
function memoryStorage(): Storage {
    const items = new Map<string, string>();

    return {
        get length() {
            return items.size;
        },
        clear: () => items.clear(),
        getItem: (key) => items.get(key) ?? null,
        key: (index) => [...items.keys()][index] ?? null,
        removeItem: (key) => {
            items.delete(key);
        },
        setItem: (key, value) => {
            items.set(key, String(value));
        }
    };
}

Object.defineProperty(globalThis, 'localStorage', { value: memoryStorage(), configurable: true });

beforeEach(async () => {
    const { chooseLanguage } = await import('@core/i18n');

    chooseLanguage('en');
});
