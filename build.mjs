/**
 * Self-contained build for dsh-client-ui-aqua.
 *
 * Produces, from the vendored src/:
 *   1. lib/client.js   — the browser client plugin, wrapped in the host's
 *                        `window.__ModuleLoader__.load({ id, factory })` format
 *                        (CJS body, externals resolved by the host: react,
 *                        react/jsx-runtime and @deepseek-ai/dsh-client-*).
 *   2. lib/index.js + lib/invariant.js — the trivial Node-side cordis plugin.
 *   3. lib/types/**    — declaration files via tsc.
 *
 * CSS handling replicates the upstream bundle semantics: every imported .css
 * is inlined as a <style> tag appended at module evaluation, and .module.css
 * object imports resolve to an identity class-name map.
 */
import { build } from 'esbuild'
import { execFileSync } from 'node:child_process'
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = dirname(fileURLToPath(import.meta.url))
const NAME = 'dsh-client-ui-aqua'

/** CSS files become JS modules: inject the stylesheet, export the class map. */
const cssPlugin = {
  name: 'aqua-css',
  setup(pluginBuild) {
    pluginBuild.onLoad({ filter: /\.css$/ }, async (args) => {
      const css = readFileSync(args.path, 'utf8')
      const classes = []
      const seen = new Set()
      for (const match of css.matchAll(/\.([A-Za-z_][A-Za-z0-9_-]*)/g)) {
        if (!seen.has(match[1])) {
          seen.add(match[1])
          classes.push(match[1])
        }
      }
      const entries = classes
        .map((name) => `  ${JSON.stringify(name)}: ${JSON.stringify(name)}`)
        .join(',\n')
      const contents = [
        `var __aquaCssText = ${JSON.stringify(css)};`,
        `var __aquaStyleEl = document.createElement("style");`,
        `__aquaStyleEl.setAttribute("data-aqua-css", "1");`,
        `__aquaStyleEl.textContent = __aquaCssText;`,
        `document.head.appendChild(__aquaStyleEl);`,
        `export default {`,
        entries,
        `};`,
        ``,
      ].join('\n')
      return { loader: 'js', contents }
    })
  },
}

// ---- 1. browser client bundle ----
const client = await build({
  entryPoints: [join(root, 'src/client/index.ts')],
  bundle: true,
  write: false,
  format: 'cjs',
  platform: 'browser',
  target: 'es2022',
  jsx: 'automatic',
  external: ['react', 'react/*', '@deepseek-ai/*'],
  plugins: [cssPlugin],
  logLevel: 'warning',
  sourcemap: false,
})

rmSync(join(root, 'lib'), { recursive: true, force: true })
mkdirSync(join(root, 'lib'), { recursive: true })

const wrapped = [
  'window.__ModuleLoader__.load({',
  `\tid: ${JSON.stringify(NAME)},`,
  '\tfactory: (require) => {',
  '\t\tvar module = { exports: {} };',
  '\t\tvar exports = module.exports;',
  client.outputFiles[0].text.trim(),
  '\t\treturn module.exports;',
  '\t}',
  '});',
  '',
].join('\n')
writeFileSync(join(root, 'lib/client.js'), wrapped)

// ---- 2. Node-side cordis plugin entries ----
await build({
  entryPoints: [join(root, 'src/index.ts'), join(root, 'src/invariant.ts')],
  bundle: true,
  format: 'esm',
  platform: 'neutral',
  target: 'es2022',
  external: ['@deepseek-ai/*'],
  outdir: join(root, 'lib'),
  outExtension: { '.js': '.js' },
  logLevel: 'warning',
  sourcemap: false,
})

// ---- 3. declaration files (best-effort: the vendored source was authored
// against the upstream monorepo's type surface, so a few strict-mode
// complaints may remain; declaration output is still emitted and the runtime
// artifacts above are unaffected). ----
const tscPath = join(root, 'node_modules/typescript/bin/tsc')
try {
  execFileSync(process.execPath, [tscPath, '-p', 'tsconfig.types.json'], { stdio: 'inherit' })
  console.log('types: ok')
} catch (error) {
  console.warn(`types: emitted with diagnostics (exit ${error.status}) — runtime artifacts are complete`)
}

console.log(`built ${NAME}`)
