import { hexColor } from '@core/categories';
import type { Category } from '@core/models';
import {
    BriefcaseMedical,
    CircleDashed,
    Coffee,
    Film,
    GraduationCap,
    House,
    LayoutGrid,
    ShoppingBag,
    ShoppingCart,
    Tag,
    TramFront,
    UtensilsCrossed,
    Wine,
    type LucideIcon
} from 'lucide-react';
import type { JSX } from 'react';

/**
 * @constant SYMBOL_ICONS
 * @description The icon standing in for each SF Symbol the app draws a category with.
 */
const SYMBOL_ICONS: Readonly<Record<string, LucideIcon>> = {
    'cart': ShoppingCart,
    'fork.knife': UtensilsCrossed,
    'wineglass': Wine,
    'cup.and.saucer': Coffee,
    'tram': TramFront,
    'bag': ShoppingBag,
    'film': Film,
    'cross.case': BriefcaseMedical,
    'graduationcap': GraduationCap,
    'square.grid.2x2': LayoutGrid,
    'circle.dashed': CircleDashed,
    'house': House
};

/**
 * @interface IconTileProps
 * @description What an icon tile shows.
 */
interface IconTileProps {
    icon: LucideIcon; /*!< The glyph */
    color: string; /*!< The tile's colour */
    size?: number; /*!< The tile's side, in pixels */
}

/**
 * @function IconTileComponent
 * @description A white glyph on a rounded coloured tile, like the icons of the iOS Settings app.
 */
export function IconTileComponent({ icon: Icon, color, size = 36 }: IconTileProps): JSX.Element {
    return (
        <span
            className="inline-flex shrink-0 items-center justify-center text-white"
            style={{ width: size, height: size, borderRadius: size * 0.28, backgroundColor: color }}
            aria-hidden="true"
        >
            <Icon size={size * 0.52} strokeWidth={2.1} />
        </span>
    );
}

/**
 * @function CategoryIconComponent
 * @description A category's tile, in its colour.
 */
export function CategoryIconComponent({ category, size }: { category: Category; size?: number }): JSX.Element {
    return <IconTileComponent icon={SYMBOL_ICONS[category.symbol] ?? Tag} color={hexColor(category.colorHex)} size={size} />;
}
