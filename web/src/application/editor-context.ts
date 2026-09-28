import { createContext, useContext } from 'react';

/**
 * @type EditorRoute
 * @description What the operation sheet is open on.
 */
export type EditorRoute = { kind: 'new' } | { kind: 'edit'; id: string };

/**
 * @interface OperationEditor
 * @description Opening the operation sheet from anywhere.
 */
export interface OperationEditor {
    openNew: () => void; /*!< Opens it on a new operation */
    openEdit: (id: string) => void; /*!< Opens it on an existing one */
}

/**
 * @constant EditorContext
 * @description Hands the editor down the tree.
 */
export const EditorContext = createContext<OperationEditor | null>(null);

/**
 * @function useOperationEditor
 * @description Opens the operation sheet.
 */
export function useOperationEditor(): OperationEditor {
    const editor = useContext(EditorContext);

    if (editor === null) {
        throw new Error('useOperationEditor must be used inside OperationEditorProvider');
    }

    return editor;
}
