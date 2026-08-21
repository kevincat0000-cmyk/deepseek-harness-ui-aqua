# dsh-client-ui-aqua (self-built)

Aqua: a highly customizable glassmorphism theme for the DeepSeek Harness Web
surface — adjustable blur and frost, fluid or wallpaper backdrop, unified
glass corners, particle whale, and motion. 带**拖拽预览**:拖动任意调节滑块时,设置面板其余部分自动隐藏、只保留该滑块,主页面效果实时可见;松开后全部恢复。

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

## 一条命令安装 (one-command install)

无需 npm、无需 git、无需账号。

**Windows(PowerShell,一条命令):**

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://raw.githubusercontent.com/kevincat0000-cmyk/dsh-client-ui-aqua/main/install.ps1' -OutFile aqua-install.ps1; .\aqua-install.ps1"
```

**macOS / Linux(一条命令):**

```sh
curl -fsSL https://raw.githubusercontent.com/kevincat0000-cmyk/dsh-client-ui-aqua/main/install.sh -o aqua-install.sh && bash aqua-install.sh
```

安装器做三件事:下载插件(默认最新 Release;`-Version 'main'` / `VERSION=main` 跟开发分支)→ 链接进 profile 的共享 `node_modules` → 在 `cordis.patch.yml` 里登记 `ui-aqua`(幂等,可重复跑)。完成后刷新 Web 界面即可;若未出现,重启 dsh web 进程。

> 国内网络若下载 GitHub 失败,可先开代理;或手动下载仓库 zip 解压后运行
> `.\install.ps1 -Source <本地目录路径>` / `SOURCE=<本地目录路径> bash install.sh`。

## 手动安装 (dsh plugin)

```sh
dsh plugin --profile web add <path-to-this-directory>
```

本包声明了 `dsh.bundle.patch`,`dsh plugin` 会自动把它追加进 profile 的 bundle 层叠;重启 web 进程并刷新页面即可。总开关在 设置 → 插件 → 玻璃主题,所有调节在 设置 → 通用设置 → 外观 下方。

## Build
