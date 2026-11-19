const INK = '#3a2a1e'

const blush = (x: number, y: number, rx = 5, ry = 3) =>
  `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="#f2a3a0" opacity="0.85"/>`

const UMBRELLA = `
<g stroke="${INK}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
<path d="M48 4V-66" fill="none"/>
<path d="M-12 -58C8 -112 92 -112 112 -60C82 -74 20 -74 -12 -58Z" fill="#6fa257"/>
<path d="M50 -66C48 -84 52 -96 60 -104M50 -66C30 -82 18 -86 6 -84M50 -66C70 -84 84 -88 96 -84" fill="none" stroke-width="1.2"/>
</g>`

const FROG = `
<g stroke="${INK}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
<ellipse cx="-30" cy="52" rx="13" ry="6" fill="#86b464"/>
<ellipse cx="30" cy="52" rx="13" ry="6" fill="#86b464"/>
<ellipse cx="0" cy="22" rx="46" ry="33" fill="#9cc77a"/>
<ellipse cx="0" cy="31" rx="26" ry="17" fill="#e7efc4" stroke-width="1.4"/>
<circle cx="-22" cy="-8" r="14" fill="#9cc77a"/>
<circle cx="22" cy="-8" r="14" fill="#9cc77a"/>
<circle cx="-22" cy="-9" r="8" fill="#fdfbf3" stroke-width="1.4"/>
<circle cx="22" cy="-9" r="8" fill="#fdfbf3" stroke-width="1.4"/>
<path d="M-11 16q11 9 22 0" fill="none"/>
</g>
<circle cx="-21" cy="-8" r="4" fill="#2a241d"/>
<circle cx="23" cy="-8" r="4" fill="#2a241d"/>
<circle cx="-19.5" cy="-9.5" r="1.4" fill="#fff"/>
<circle cx="24.5" cy="-9.5" r="1.4" fill="#fff"/>
${blush(-29, 12, 6, 3.5)}${blush(29, 12, 6, 3.5)}`

const HEDGEHOG = `
<g stroke="${INK}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<path d="M-42 14L-48 -4L-36 -8L-38 -24L-24 -22L-20 -38L-7 -30L1 -44L10 -30L22 -38L25 -22L39 -24L36 -8L48 -4L42 14Z" fill="#8a5a3a"/>
<ellipse cx="-14" cy="30" rx="8" ry="5" fill="#d9b48a"/>
<ellipse cx="14" cy="30" rx="8" ry="5" fill="#d9b48a"/>
<ellipse cx="0" cy="8" rx="28" ry="21" fill="#f1d6ad"/>
</g>
<circle cx="-9" cy="3" r="2.8" fill="#2a241d"/>
<circle cx="9" cy="3" r="2.8" fill="#2a241d"/>
<circle cx="0" cy="11" r="3.4" fill="#2a241d"/>
${blush(-17, 12)}${blush(17, 12)}
<path d="M-4 17q4 3 8 0" fill="none" stroke="${INK}" stroke-width="1.4" stroke-linecap="round"/>`

const CAT = `
<g stroke="${INK}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<path d="M30 6C58 2 66 -22 50 -30C42 -34 36 -26 44 -22" fill="none" stroke="#c97a3c" stroke-width="7"/>
<path d="M30 6C58 2 66 -22 50 -30C42 -34 36 -26 44 -22" fill="none" stroke-width="1.2"/>
<ellipse cx="4" cy="0" rx="34" ry="18" fill="#f0a868"/>
<path d="M-10 -14q4 8 0 16M2 -17q4 9 0 18M14 -15q4 8 0 15" fill="none" stroke="#c97a3c" stroke-width="2.4"/>
<path d="M-40 -16L-38 -34L-28 -24Z" fill="#f0a868"/>
<path d="M-18 -18L-16 -36L-28 -26Z" fill="#f0a868"/>
<circle cx="-28" cy="-8" r="16" fill="#f0a868"/>
<path d="M-36 -9q3 3 6 0M-24 -9q3 3 6 0" fill="none" stroke-width="1.6"/>
<path d="M-30 -2q2 2 4 0" fill="none" stroke-width="1.4"/>
</g>
${blush(-38, -2, 4, 2.5)}${blush(-18, -2, 4, 2.5)}`

const SNAIL = `
<g stroke="${INK}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<path d="M-38 20Q-40 6 -26 4H22Q34 4 40 -10L46 -26M40 -10L34 -28" fill="#c9d39a"/>
<path d="M-38 20H30Q44 20 40 -10" fill="#c9d39a"/>
<circle cx="-4" cy="-10" r="22" fill="#e9b36a"/>
<path d="M-4 -10m-4 0a4 4 0 1 1 8 0a9 9 0 1 1 -17 0a14 14 0 1 1 27 0" fill="none" stroke-width="1.6"/>
</g>
<circle cx="46" cy="-27" r="3" fill="#2a241d"/>
<circle cx="34" cy="-29" r="3" fill="#2a241d"/>
${blush(34, 2, 4, 2.4)}`

const stick = (body: string, tip: string, band: string) => `
<g transform="rotate(-12)" stroke="${INK}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">
<path d="M-11 -6L0 -32L11 -6Z" fill="${tip}"/>
<rect x="-11" y="-6" width="22" height="38" rx="5" fill="${body}"/>
<rect x="-11" y="2" width="22" height="16" fill="${band}" stroke-width="1.4"/>
</g>
<g transform="rotate(-12)">
<circle cx="-5" cy="9" r="2.4" fill="#2a241d"/>
<circle cx="5" cy="9" r="2.4" fill="#2a241d"/>
${blush(-8, 14, 3, 2)}${blush(8, 14, 3, 2)}
<path d="M-3 14q3 3 6 0" fill="none" stroke="${INK}" stroke-width="1.3" stroke-linecap="round"/>
</g>`

const INKY = stick('#4a6fc0', '#f1d6ad', '#7d9be0')
const SUNNY = stick('#e8804f', '#c95f33', '#f6dfb2')

const FILTER = `<defs><filter id="hand" x="-10%" y="-10%" width="120%" height="120%">
<feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="7" result="wob"/>
<feDisplacementMap in="SourceGraphic" in2="wob" scale="2.2" xChannelSelector="R" yChannelSelector="G" result="w"/>
<feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="3" result="g"/>
<feColorMatrix in="g" type="matrix" values="0 0 0 0 0.2  0 0 0 0 0.13  0 0 0 0 0.07  0 0 0 0.9 -0.32" result="specks"/>
<feComposite in="specks" in2="w" operator="in" result="grain"/>
<feMerge><feMergeNode in="w"/><feMergeNode in="grain"/></feMerge>
</filter></defs>`

const svg = (viewBox: string, body: string, width: number, height: number) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="${viewBox}">${FILTER}<g filter="url(#hand)">${body}</g></svg>`

export type Critter = 'inky' | 'sunny' | 'pip' | 'kero' | 'miso' | 'dot'

const FACE: Record<Critter, string> = {
  inky: INKY,
  sunny: SUNNY,
  pip: `<g transform="translate(0 2) scale(0.66)">${HEDGEHOG}</g>`,
  kero: `<g transform="translate(0 -12) scale(0.66)">${FROG}</g>`,
  miso: `<g transform="translate(-8 10) scale(0.66)">${CAT}</g>`,
  dot: `<g transform="translate(-4 6) scale(0.72)">${SNAIL}</g>`,
}

export const AVATAR_PX = 28
export const avatar = (who: Critter) => svg('-40 -40 80 80', FACE[who], AVATAR_PX, AVATAR_PX)

export type Mascot = { name: string; art: string }
export const MASCOT_PX = { width: 150, height: 120 }
const mascot = (viewBox: string, body: string) => svg(viewBox, body, MASCOT_PX.width, MASCOT_PX.height)

export const MASCOTS: readonly Mascot[] = [
  { name: 'kero', art: mascot('-60 -120 180 190', UMBRELLA + FROG) },
  { name: 'pip', art: mascot('-60 -55 120 100', HEDGEHOG) },
  { name: 'miso', art: mascot('-55 -45 125 75', CAT) },
  { name: 'dot', art: mascot('-50 -45 110 75', SNAIL) },
]

const READS = new Set(['Read', 'Grep', 'Glob', 'WebFetch', 'WebSearch', 'ToolSearch', 'LS'])
const EDITS = new Set(['Edit', 'Write', 'NotebookEdit', 'MultiEdit'])

export function critterFor(tool: string): Critter {
  if (READS.has(tool)) return 'pip'
  if (EDITS.has(tool)) return 'kero'
  if (tool === 'Bash') return 'miso'
  return 'dot'
}

export function tally(count: number): string {
  const shown = Math.min(count, 20)
  const groups = Math.ceil(shown / 5)
  let marks = ''
  for (let g = 0; g < groups; g++) {
    const x = g * 26
    const inGroup = Math.min(5, shown - g * 5)
    for (let i = 0; i < Math.min(4, inGroup); i++) {
      marks += `<path d="M${x + 3 + i * 5} 3l-1 14"/>`
    }
    if (inGroup === 5) marks += `<path d="M${x} 13L${x + 22} 6"/>`
  }
  const width = Math.max(groups, 1) * 26
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="20" viewBox="0 0 ${width} 20"><g fill="none" stroke="#b8382e" stroke-width="2.2" stroke-linecap="round">${marks}</g></svg>`
}

export function pencil(percentLeft: number): string {
  const length = 20 + Math.round(1.5 * Math.max(0, Math.min(100, percentLeft)))
  const end = 16 + length
  return `<svg xmlns="http://www.w3.org/2000/svg" width="200" height="18" viewBox="0 0 220 20">${FILTER}<g filter="url(#hand)" stroke="${INK}" stroke-width="1.4" stroke-linejoin="round">
<rect x="2" y="5" width="9" height="10" rx="2" fill="#e98a8a"/>
<rect x="11" y="5" width="6" height="10" fill="#b9b2a6"/>
<rect x="17" y="5" width="${length}" height="10" fill="#f2c14e"/>
<path d="M${17} 10H${end}" stroke="#d9a53a" stroke-width="1"/>
<path d="M${end + 1} 5L${end + 16} 10L${end + 1} 15Z" fill="#f1d6ad"/>
<path d="M${end + 11} 8.4L${end + 16} 10L${end + 11} 11.6Z" fill="#3a3a3a"/>
</g></svg>`
}

// For terminals that draw no pictures: each one two cells wide, the width of a row's bullet.
export const EMOJI: Record<Critter, string> = {
  inky: '🐙',
  sunny: '🌻',
  pip: '🦔',
  kero: '🐸',
  miso: '🐱',
  dot: '🐌',
}
