import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import { MODULE_DOCUMENTS_BY_ID } from '../catalog/documents'
import MACHINE_MODULES from '../catalog/machine-modules.json'
import { FirmwareFeedbackDialog } from '../components/FirmwareFeedbackDialog'
import { builtModules } from './build-follow-up'
import { downloadedModuleGuide } from './downloaded-module-guide'
import { moduleMediaDocument } from './module-media'

describe('downloaded module guides', () => {
  it('resolves real usage and every media item for current OT and machine-qualified Digi versions', () => {
    const ids = [...Object.keys(MODULE_DOCUMENTS_BY_ID), ...MACHINE_MODULES.modules.map(module => module.machine + '-' + module.id)]
    for (const module of builtModules(ids)) {
      const guide = downloadedModuleGuide(module)!
      expect(guide, module.id).toBeDefined()
      expect(guide.summary, module.id).toBeTruthy()
      expect(guide.steps.length, module.id).toBeGreaterThan(0)
      expect(guide.screenshots.every(item => item.captureType !== 'audio')).toBe(true)
      expect(guide.audio.every(item => item.captureType === 'audio')).toBe(true)
      expect([...guide.screenshots, ...guide.audio].map(item => item.path).sort()).toEqual(moduleMediaDocument(module.id)!.media.map(item => item.path).sort())
    }
    const [digitakt, digitone] = builtModules(['digitakt-digihealth', 'digitone-digihealth'])
    expect(downloadedModuleGuide(digitakt)?.thumbnail).toContain('/digitakt-digihealth/' + digitakt.version + '/')
    expect(downloadedModuleGuide(digitone)?.thumbnail).toContain('/digitone-digihealth/' + digitone.version + '/')
  })
  it('does not substitute current instructions or screenshots for an older or unknown build', () => {
    expect(downloadedModuleGuide({ id: 'miniverb', name: 'Mini Verb', version: '0.1.1-experimental' })).toBeUndefined()
    expect(downloadedModuleGuide({ id: 'unknown', name: 'Unknown', version: '1.0.0' })).toBeUndefined()
    const [verb] = builtModules(['miniverb'])
    const guide = downloadedModuleGuide(verb)!
    expect(guide.screenshots[guide.initialScreenshot]).toMatchObject({ otUi: { shows: 'controls' } })
    expect(guide.steps.at(-1)?.text).toContain('TONE 64 is neutral')
    expect(guide.screenshots[guide.initialScreenshot].caption).toContain('encoder F')
  })
  it('uses a module’s own longer usage instructions where no short test exists', () => {
    const [module] = builtModules(['usb-audio-out-tracks-main-cue'])
    const document = MODULE_DOCUMENTS_BY_ID[module.id]
    const guide = downloadedModuleGuide(module)!
    expect(guide.steps.map(step => step.text)).toEqual(document.presentation.usage)
    expect(guide.screenshots).toEqual([])
    expect(guide.noUiReason).toBeTruthy()
    expect(guide.noUiReason).not.toMatch(/reviewer/i)
  })
})

function render(modules = builtModules(['miniverb', 'tapeecho', 'euclid', 'repitch']), pendingIds?: string[]) {
  return renderToStaticMarkup(createElement(FirmwareFeedbackDialog, {
    build: { machine: 'Octatrack', os: '1.40C', modules }, inline: true, pendingIds,
    onConfirm: async () => {}, onReport: () => {}, onLater: () => {}, onClose: () => {},
  }))
}

describe('downloaded firmware overview', () => {
  it('keeps completed companions available and teaches the selected module in the same overlay', () => {
    const html = render(undefined, ['tapeecho'])
    for (const module of builtModules(['miniverb', 'tapeecho', 'euclid', 'repitch'])) {
      expect(html).toContain('How to use ' + module.name)
      expect(html).toContain(module.version)
    }
    expect(html).toContain('Feedback saved')
    expect(html).toContain('Mini Verb main FX2 page')
    expect(html).toContain('Quick test')
    expect(html).toContain('Enlarge Mini Verb screenshot')
    expect(html).toContain('Full setup steps')
    expect(html).toContain('Next: Tape Echo')
    expect(html).toContain('Flashing guide')
    expect(html).not.toMatch(/<a\s/)
    expect(html).not.toContain('Select all')
  })
  it('keeps feedback possible with the exact old version while explaining missing historical guidance', () => {
    const html = render([{ id: 'miniverb', name: 'Mini Verb', version: '0.1.1-experimental' }])
    expect(html).toContain('downloaded version (0.1.1-experimental)')
    expect(html).toContain('Mini Verb: works for me')
    expect(html).toContain('Report an issue with Mini Verb')
    expect(html).not.toContain('module-media/')
    expect(html).not.toContain('TONE 64')
  })
})
