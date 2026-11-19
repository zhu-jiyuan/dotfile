import type { ThemeSetArgs } from 'claude-code'

import { makeColors } from './make-colors.js'

export const SCENE_ID = 'notebook'

const { theme, problems } = makeColors({
  label: 'Notebook',
  only: 'light',
  roles: { accent: '#2f4f9f', danger: '#b8382e', success: '#4f8a3b', warning: '#b8731a', pro: '#7a4f9a' },
  light: {
    gray: {
      anchors: {
        'surface-0': '#efede6',
        'surface-1': '#f5f3ed',
        'surface-2': '#faf9f5',
        'text-primary': '#2f2c28',
        'text-secondary': '#524e47',
        'text-muted': '#69645b',
      },
    },
  },
})

export const COLOR_PROBLEMS = problems

export const LOOK: ThemeSetArgs = {
  colors: theme,
  overrideColorScheme: 'light',
  backdrop: { scene: SCENE_ID, glass: { blur: 0, opacity: 0.38 } },
}

export const PAPER = `<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%">
<defs>
<pattern id="rule" width="40" height="26" patternUnits="userSpaceOnUse">
<path d="M0 25.5H40" stroke="#b7c8df" stroke-width="1"/>
</pattern>
<filter id="grain" x="0" y="0" width="100%" height="100%">
<feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="2" seed="5" result="g"/>
<feColorMatrix in="g" type="matrix" values="0 0 0 0 0.35  0 0 0 0 0.3  0 0 0 0 0.22  0 0 0 0.35 -0.1"/>
</filter>
<radialGradient id="hole" cx="0.42" cy="0.38" r="0.65">
<stop offset="0" stop-color="#5b5148"/>
<stop offset="0.7" stop-color="#2e2722"/>
<stop offset="1" stop-color="#1c1714"/>
</radialGradient>
</defs>
<rect width="100%" height="100%" fill="#f4f2ec"/>
<rect width="100%" height="100%" filter="url(#grain)"/>
<rect y="64" width="100%" height="100%" fill="url(#rule)"/>
<path d="M27 0V4000" stroke="#e08f86" stroke-width="1.3"/>
<path d="M30 0V4000" stroke="#e08f86" stroke-width="0.6" opacity="0.7"/>
<g>
<circle cx="13" cy="16%" r="7" fill="url(#hole)"/>
<circle cx="13" cy="50%" r="7" fill="url(#hole)"/>
<circle cx="13" cy="84%" r="7" fill="url(#hole)"/>
</g>
</svg>`
