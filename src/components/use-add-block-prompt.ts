import { useId, useState, type RefObject } from 'react'
import type { AddBlock } from '../catalog/add-blocks'

// Open state for the swap prompt. It is keyed to the conflict it describes, so a prompt does not outlive a selection change.
// The caller owns the ref of its add button: closing returns focus there.
export function useAddBlockPrompt(block: AddBlock | undefined, trigger: RefObject<HTMLButtonElement | null>) {
  const [asked, setAsked] = useState<string>()
  const id = useId()
  const conflict = block?.kind === 'conflict' ? block : undefined
  const open = !!conflict && asked === conflict.key
  return {
    conflict, open, id,
    toggle: () => setAsked(open ? undefined : conflict?.key),
    close: () => { setAsked(undefined); trigger.current?.focus() },
  }
}
