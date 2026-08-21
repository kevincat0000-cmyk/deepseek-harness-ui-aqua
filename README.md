# dsh-client-ui-aqua (self-built)

Aqua: a highly customizable glassmorphism theme for the DeepSeek Harness Web
surface — adjustable blur and frost, fluid or wallpaper backdrop, unified
glass corners, particle whale, and motion.

## Provenance

This package is **self-built**: the plugin design and source are vendored from
the MIT-licensed open-source project
[WYH66666666/DSH-Transparent-UI-Plugin](https://github.com/WYH66666666/DSH-Transparent-UI-Plugin),
and rebuilt here with our own local toolchain instead of consuming the author's
npm distribution:

- `src/` — vendored plugin source (MIT, see `LICENSE`).
- `build.mjs` — our own esbuild pipeline that produces the host module format
  (`window.__ModuleLoader__.load` factory), inlines CSS as runtime `<style>`
  injection, and emits the Node-side cordis entry plus type declarations.
- `cordis.patch.yml` — the profile patch layer registering the `ui-aqua` row
  into the web profile's browser roster.

## Build

```sh
pnpm install
pnpm run build   # -> lib/client.js, lib/index.js, lib/invariant.js, lib/types/
```

## Install

```sh
dsh plugin --profile web add <path-to-this-directory>
```

The package declares `dsh.bundle.patch`, so `dsh plugin` appends it to the
profile's bundle stack automatically. Restart the web process and reload the
page; the master switch lives in Settings → Plugins → 玻璃主题, with every
knob under Settings → General → Appearance.
