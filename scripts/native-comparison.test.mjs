import { describe, expect, it } from 'vitest'
import { refusalClass } from './native-comparison.mjs'

describe('native refusal equivalence', () => {
  it('classifies guarded hook overlaps as collisions while retaining other failures', () => {
    expect(refusalClass("remix 'test' has colliding modules: hook site: repitch and poly8", 'native')).toBe('declaration collision')
    expect(refusalClass('The OS write plan contains overlapping guards.', 'browser')).toBe('declaration collision')
    expect(refusalClass('conflicting native declarations', 'browser')).toBe('declaration collision')
    for (const error of ['The OS write plan has an invalid guarded range.', 'The original OS does not match the guard for polyui.', 'unresolved replay']) expect(refusalClass(error, 'browser')).toBe('unclassified')
  })
})
