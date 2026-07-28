import { z } from 'zod';

/**
 * @constant IdSchema
 * @description Reusable schema for a client-minted entity id. The client uses both
 * semantic ids (e.g. "groceries") and UUIDs, so this only bounds the length.
 */
export const IdSchema = z.string().min(1).max(64);

/**
 * @constant ColorSchema
 * @description Reusable schema for a packed 0xRRGGBB colour stored as an integer.
 */
export const ColorSchema = z.number().int().min(0).max(0xffffff);
