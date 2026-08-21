#!/usr/bin/env bash
# dsh-client-ui-aqua one-command installer (macOS / Linux).
#
# One line:
#   curl -fsSL https://raw.githubusercontent.com/kevincat0000-cmyk/dsh-client-ui-aqua/main/install.sh -o aqua-install.sh && bash aqua-install.sh
#
# Same three steps as install.ps1: fetch the plugin (zip, then git fallback),
# symlink it into the profile's shared node_modules fallback, and register
# ui-aqua in the web profile's cordis.patch.yml (idempotent).
set -euo pipefail

SOURCE="${SOURCE:-https://github.com/kevincat0000-cmyk/dsh-client-ui-aqua}"
VERSION="${VERSION:-latest}"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
PROFILE="${PROFILE:-web}"

PLUGIN=dsh-client-ui-aqua
NODE_MODULES="$DSH_HOME/profiles/node_modules"
LINK_PATH="$NODE_MODULES/$PLUGIN"
PATCH_FILE="$DSH_HOME/profiles/$PROFILE/cordis.patch.yml"
PLUGINS_DIR="$DSH_HOME/plugins"
CLONE_DIR="$PLUGINS_DIR/$PLUGIN"

if [ ! -d "$DSH_HOME" ]; then
  echo "DSH home not found: $DSH_HOME (set DSH_HOME to override)" >&2
  exit 1
fi

# ---------- 1. source ----------
echo "[1/3] Getting plugin source..."
if [[ "$SOURCE" =~ ^(https?://|git@|ssh://|github:) ]]; then
  REPO_URL="${SOURCE%/}"
  REPO_URL="${REPO_URL%.git}"
  REF="$VERSION"
  IS_TAG=false
  if [[ "$REF" =~ ^v[0-9]+\.[0-9]+ ]]; then IS_TAG=true; fi
  if [ "$REF" = "latest" ] && [[ "$REPO_URL" =~ ^https?://github\.com/([^/]+/[^/]+) ]]; then
    SLUG="${BASH_REMATCH[1]}"
    if LATEST_TAG="$(curl -fsSL --max-time 15 "https://api.github.com/repos/$SLUG/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')" && [ -n "$LATEST_TAG" ]; then
      REF="$LATEST_TAG"; IS_TAG=true
      echo "  newest release: $REF"
    else
      echo "  (release lookup failed, falling back to the main branch)"
      REF=main; IS_TAG=false
    fi
  fi

  REF_KIND=heads; [ "$IS_TAG" = true ] && REF_KIND=tags
  ZIP_URL="$REPO_URL/archive/refs/$REF_KIND/$REF.zip"
  ZIP_FILE="$PLUGINS_DIR/aqua-plugin.zip"
  EXTRACT_DIR="$PLUGINS_DIR/aqua-plugin-extract"
  mkdir -p "$PLUGINS_DIR"

  GOT_SOURCE=false
  if echo "  downloading $ZIP_URL" && curl -fSL "$ZIP_URL" -o "$ZIP_FILE"; then
    rm -rf "$EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"
    if unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR"; then
      INNER="$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
      if [ -n "$INNER" ]; then
        rm -rf "$CLONE_DIR"
        mv "$INNER" "$CLONE_DIR"
        rm -f "$ZIP_FILE"
        GOT_SOURCE=true
      fi
    fi
  fi
  if [ "$GOT_SOURCE" = false ]; then
    echo "  zip download failed, trying git clone..."
    command -v git >/dev/null 2>&1 || { echo "download failed (zip and git both unavailable)" >&2; exit 1; }
    rm -rf "$CLONE_DIR"
    git clone --depth 1 --branch "$REF" "$REPO_URL" "$CLONE_DIR"
  fi
  SRC="$CLONE_DIR"
else
  SRC="$(cd "$SOURCE" && pwd)"
fi
if [ ! -f "$SRC/lib/client.js" ]; then
  echo "lib/client.js not found - the repo must include the pre-built bundle. dir: $SRC" >&2
  exit 1
fi

# ---------- 2. symlink ----------
echo "[2/3] Linking -> $LINK_PATH"
mkdir -p "$NODE_MODULES"
if [ -e "$LINK_PATH" ] || [ -L "$LINK_PATH" ]; then rm -rf "$LINK_PATH"; fi
ln -s "$SRC" "$LINK_PATH"
if [ ! -e "$LINK_PATH" ]; then echo "symlink creation failed" >&2; exit 1; fi

# ---------- 3. register ----------
echo "[3/3] Registering in $PATCH_FILE"
ENTRY=$(cat <<'EOF'
- insert:
    - id: ui-aqua
      name: 'dsh-client-ui-aqua'
EOF
)
if [ ! -f "$PATCH_FILE" ]; then
  printf '%s\n\n' "$ENTRY" > "$PATCH_FILE"
elif grep -qE '^[[:space:]]*-[[:space:]]+id:[[:space:]]*ui-aqua[[:space:]]*$' "$PATCH_FILE"; then
  echo "  already registered, skip."
else
  # strip a trailing empty-list stub before appending
  perl -0pi -e 's/\[\s*\]\s*\z//' "$PATCH_FILE" 2>/dev/null || sed -i -e ':a' -e '/^\s*\[\s*\]\s*$/{$d;N;ba}' "$PATCH_FILE"
  printf '\n%s\n' "$ENTRY" >> "$PATCH_FILE"
fi

echo
echo "Done. Reload the Web UI (Aqua is on by default; Settings -> Plugins -> Aqua to toggle)."
echo "If the plugin does not appear after reload, restart the dsh web process."
