import type { EditorRoute, OperationEditor } from '@application/editor-context';
import { EditorContext } from '@application/editor-context';
import OperationSheet from '@pages/operations/operation-sheet';
import { useCallback, useMemo, useState, type JSX, type ReactNode } from 'react';

/**
 * @function OperationEditorProvider
 * @description Holds the one operation sheet every page opens.
 */
function OperationEditorProvider({ children }: { children: ReactNode }): JSX.Element {
    const [route, setRoute] = useState<EditorRoute | null>(null);
    const openNew = useCallback(() => setRoute({ kind: 'new' }), []);
    const openEdit = useCallback((id: string) => setRoute({ kind: 'edit', id }), []);
    const editor = useMemo<OperationEditor>(() => ({ openNew, openEdit }), [openNew, openEdit]);

    return (
        <EditorContext.Provider value={editor}>
            {children}
            <OperationSheet route={route} onClose={() => setRoute(null)} />
        </EditorContext.Provider>
    );
}

export default OperationEditorProvider;
