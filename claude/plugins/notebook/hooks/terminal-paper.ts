import type { EngineInterface } from 'claude-code'

// The terminal draws no look, but it takes the standard color escapes: OSC 11 sets the
// window's background, OSC 10 its text and OSC 12 its cursor; 110-112 put back its own.
const osc = (code: string) => `\u001b]${code}\u0007`

export const PAPER_ON = osc('11;#f4f2ec') + osc('10;#2f2c28') + osc('12;#2f4f9f')
export const PAPER_OFF = osc('111') + osc('110') + osc('112')

export async function paintTerminal($: EngineInterface, sequence: string): Promise<void> {
  await $.process.run(['/bin/sh', '-c', 'printf %s "$1" > /dev/tty', 'sh', sequence], { timeoutMs: 2000 })
}

// What the terminal draws for itself. Images: kitty and Ghostty, and iTerm2 3.5+ in fullscreen.
// Ruled paper: Ghostty, whose own config (dotfile/ghostty) lays the paper under every window.
export async function terminalTraits($: EngineInterface): Promise<{ pictures: boolean; ownPaper: boolean }> {
  const { stdout } = await $.process.run(['/bin/sh', '-c', 'printf "%s|%s|%s" "$TERM_PROGRAM" "$TERM" "$KITTY_WINDOW_ID"'], { timeoutMs: 2000 })
  const [program = '', term = '', kitty = ''] = stdout.split('|')
  const pictures = ['ghostty', 'iTerm.app', 'kitty'].includes(program) || term.includes('kitty') || term.includes('ghostty') || kitty !== ''
  return { pictures, ownPaper: program === 'ghostty' }
}

// Ruled lines and a red margin, as kitty-protocol pictures laid under the text: the z-index below
// -1073741824 draws them beneath cells with a background of their own, so notes cover them. Ghostty
// and Rex both speak the protocol. One 8x48 strip with a line along its foot fills each row, and
// one 24x24 cell with a stripe on its left edge runs down the window's left side.
const RULE = { id: 7701, png: 'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAwCAYAAAAsJjtLAAAAHUlEQVR42mNgGAWjYBSMglEwAsD2E/f/48MEFQAA7uI10d/vxY8AAAAASUVORK5CYII=' }
const MARGIN = { id: 7702, png: 'iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVR42mN40N/2H4YZaAFGLRi1YNSCUQtGLRi1YNSCUQuGhgUA4a/UobuMnXIAAAAASUVORK5CYII=' }
const UNDER_CELLS = -1073741825

const apc = (body: string) => `\u001b_G${body}\u001b\\`

export function ruledLines(rows: number, columns: number, transmit: boolean): string {
  let out = '\u001b7'
  if (transmit) {
    out += apc(`a=t,f=100,i=${RULE.id},q=2;${RULE.png}`) + apc(`a=t,f=100,i=${MARGIN.id},q=2;${MARGIN.png}`)
  }
  out += apc(`a=d,d=i,i=${RULE.id},q=2`) + apc(`a=d,d=i,i=${MARGIN.id},q=2`)
  for (let row = 1; row <= rows; row++) {
    out += `\u001b[${row};1H` + apc(`a=p,i=${RULE.id},p=${row},c=${columns},r=1,z=${UNDER_CELLS - 1},C=1,q=2`)
  }
  out += '\u001b[1;1H' + apc(`a=p,i=${MARGIN.id},p=1,c=1,r=${rows},z=${UNDER_CELLS},C=1,q=2`)
  return out + '\u001b8'
}

export const LINES_OFF = apc(`a=d,d=I,i=${RULE.id},q=2`) + apc(`a=d,d=I,i=${MARGIN.id},q=2`)
