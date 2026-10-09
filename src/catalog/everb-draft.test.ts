import { describe, expect, it } from 'vitest'
import { resolve } from 'node:path'
import { readFile } from 'node:fs/promises'
import { createHash } from 'node:crypto'
import draft from '../../sdk/drafts/everb/octamod.module.json'
import capture from '../../sdk/drafts/everb/media/capture.json'
import performance from '../../sdk/drafts/everb/evidence/performance.json'
import baseline from '../../sdk/module-qualification-baseline.json'
import { parseModuleDocument, requireModuleUiForPublication, requireModuleQualificationForPublication } from './module-contract'
import { requireModuleResourceImpact } from './resource-impact'
import { moduleNativeSourceSha256, parseQualificationBaseline, requireFolderQualification } from '../../scripts/module-qualification.mjs'
import { requireCompleteReadme, requireMonochromePng } from '../../scripts/module-documentation.mjs'
import { MODULES, resolveSelection } from './modules'

const folder = resolve('sdk/drafts/everb')

describe('E-Verb staged draft', () => {
  it('stays out of the catalog until hardware evidence or an owner waiver qualifies it', async () => {
    const document = parseModuleDocument(draft)
    expect(document.tests.hardwareStatus).toBe('untested')
    expect(document.tests.qualification).toBeUndefined()
    expect(() => requireModuleQualificationForPublication(document)).toThrow('worst-case cycles, exact memory and hardware')
    await expect(requireFolderQualification(folder, document, parseQualificationBaseline(baseline))).rejects.toThrow('worst-case cycles, exact memory and hardware')
    expect(MODULES.some(module => module.id === document.id)).toBe(false)
    expect(() => resolveSelection([document.id])).toThrow('Unknown module')
  })

  it('carries a complete tutorial, gauges and real monochrome captures of this version', async () => {
    const document = parseModuleDocument(draft)
    expect(() => requireModuleUiForPublication(document)).not.toThrow()
    expect(() => requireModuleResourceImpact(document)).not.toThrow()
    requireCompleteReadme(document, await readFile(resolve(folder, 'README.md'), 'utf8'))
    expect(capture.moduleId).toBe(document.id)
    expect(capture.moduleVersion).toBe(document.version)
    // The captures are bound to this exact native source: any source change needs a new capture.
    expect(capture.sourceSha256).toBe(await moduleNativeSourceSha256(folder, document))
    expect(capture.stockOs.mainOsSha256).toMatch(/^[a-f0-9]{64}$/)
    for (const media of document.media) {
      const bytes = await readFile(resolve(folder, media.path))
      requireMonochromePng(bytes)
      expect(createHash('sha256').update(bytes).digest('hex')).toBe(capture.screenshots[media.path.slice('media/'.length) as keyof typeof capture.screenshots])
      expect(media.otUi?.moduleVersion).toBe(document.version)
      expect(media.otUi?.imageSha256).toBe(capture.imageSha256)
    }
  })

  it('keeps its performance record on this version (npm run perf:audit -- check judges it)', () => {
    expect(performance.module).toBe(draft.id)
    expect(performance.version).toBe(draft.version)
    expect(performance.stress.clobbers).toBe(0)
    expect(performance.stress.hangs).toBe(0)
  })
})
