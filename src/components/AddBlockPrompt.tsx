import { moduleNameList, type AddBlock } from '../catalog/add-blocks'
import { Icon } from './Icon'

// A chip that is always visible and a prompt that opens from the add button, for a module that conflicts with the
// configuration. A conflict never disables the add, because a configuration with conflicts can be saved and fixed later.
// The prompt offers the swap that avoids it.
export function AddBlockChip({ block }: { block: AddBlock }) {
  return <span className={'module-compatibility-badge module-card-compatibility add-block-chip' + (block.kind === 'conflict' ? ' is-conflict' : '')} title={block.detail}><Icon name={block.kind === 'conflict' ? 'swap' : 'sliders'} size={12} />{block.reason}</span>
}

export function AddBlockPrompt({ id, name, block, onSwap, onAddAnyway, onCancel }: { id: string; name: string; block: AddBlock; onSwap: () => void; onAddAnyway: () => void; onCancel: () => void }) {
  const swap = block.swapRemoveIds
  return <div className="add-block-prompt" id={id} role="group" aria-label={name + ' conflicts with your configuration'} onKeyDown={event => { if (event.key === 'Escape') { event.stopPropagation(); onCancel() } }}>
    <p>{block.detail}</p>
    <div className="add-block-actions">
      {swap && <button type="button" className="button button-primary" onClick={onSwap}><Icon name="swap" size={14} />{'Remove ' + (swap.length > 2 ? swap.length + ' modules' : moduleNameList(swap)) + ' and add ' + name}</button>}
      <button type="button" className="button button-quiet" onClick={onAddAnyway} title="Add it and choose what to keep in your configuration">Add anyway</button>
      <button type="button" className="text-button" onClick={onCancel}>Cancel</button>
    </div>
  </div>
}
