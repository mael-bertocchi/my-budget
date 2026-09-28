import type { Category } from '@core/models';

/**
 * @constant DEFAULT_CATEGORIES
 * @description The catalogue the app ships with, used when the server has never been sent any category.
 */
export const DEFAULT_CATEGORIES: readonly Category[] = [
    { id: 'groceries', name: 'Groceries', symbol: 'cart', colorHex: 0x3ecf8e, monthlyLimit: 400 },
    { id: 'restaurant', name: 'Restaurant', symbol: 'fork.knife', colorHex: 0xffa23e, monthlyLimit: 250 },
    { id: 'bar', name: 'Bar', symbol: 'wineglass', colorHex: 0x8fe05c, monthlyLimit: 100 },
    { id: 'coffee', name: 'Coffee', symbol: 'cup.and.saucer', colorHex: 0xdf74e7, monthlyLimit: 50 },
    { id: 'transport', name: 'Transport', symbol: 'tram', colorHex: 0x4d9bff, monthlyLimit: 150 },
    { id: 'shopping', name: 'Shopping', symbol: 'bag', colorHex: 0xff6ba8, monthlyLimit: 180 },
    { id: 'fun', name: 'Fun', symbol: 'film', colorHex: 0x38d6d6, monthlyLimit: 120 },
    { id: 'health', name: 'Health', symbol: 'dumbbell', colorHex: 0xff8a5c, monthlyLimit: 80 },
    { id: 'school', name: 'School', symbol: 'graduationcap', colorHex: 0xffd166, monthlyLimit: 120 },
    { id: 'miscellaneous', name: 'Miscellaneous', symbol: 'square.grid.2x2', colorHex: 0x9ba1b0, monthlyLimit: 100 }
];

/**
 * @constant FALLBACK_CATEGORY
 * @description What an operation filed under an unknown category is drawn as.
 */
export const FALLBACK_CATEGORY: Category = {
    id: 'uncategorized',
    name: 'Uncategorized',
    symbol: 'circle.dashed',
    colorHex: 0xa78bfa,
    monthlyLimit: 0
};

/**
 * @function hexColor
 * @description A packed 0xRRGGBB colour as CSS.
 */
export function hexColor(value: number): string {
    return `#${value.toString(16).padStart(6, '0')}`;
}

/**
 * @function categoriesOf
 * @description The categories to offer: the stored ones, or the shipped catalogue when none were ever stored.
 *
 * @param {readonly Category[]} categories The stored categories.
 *
 * @returns {readonly Category[]} The categories to offer.
 */
export function categoriesOf(categories: readonly Category[]): readonly Category[] {
    return categories.length > 0 ? categories : DEFAULT_CATEGORIES;
}

/**
 * @function categoryOrFallback
 * @description Looks a category up by id, falling back to the uncategorized stand-in.
 *
 * @param {readonly Category[]} categories The stored categories.
 * @param {string} id The id to find.
 *
 * @returns {Category} The category.
 */
export function categoryOrFallback(categories: readonly Category[], id: string): Category {
    return categoriesOf(categories).find((category) => category.id === id) ?? FALLBACK_CATEGORY;
}
