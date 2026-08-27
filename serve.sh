#!/usr/bin/env bash
#
# Local preview for the site: installs gems on first run, then serves with
# livereload on http://localhost:4000 (VSCode forwards the port automatically).
#
#   ./serve.sh              # serve on port 4000
#   ./serve.sh --port 4001  # serve on another port
#   ./serve.sh --clean      # drop _site/ and the Jekyll cache first
#   ./serve.sh --build      # build once into _site/ instead of serving
#
# Any other flags are passed straight through to `jekyll serve`.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

PORT=4000
LIVERELOAD_PORT=""
CLEAN=0
BUILD_ONLY=0
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) PORT="$2"; shift 2 ;;
    --port=*) PORT="${1#*=}"; shift ;;
    --livereload-port) LIVERELOAD_PORT="$2"; shift 2 ;;
    --livereload-port=*) LIVERELOAD_PORT="${1#*=}"; shift ;;
    --clean) CLEAN=1; shift ;;
    --build) BUILD_ONLY=1; shift ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
    *) EXTRA_ARGS+=("$1"); shift ;;
  esac
done

say() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit 1; }

# --- Ruby -------------------------------------------------------------------

command -v ruby >/dev/null || die "ruby not found. Install it with: sudo apt install ruby-full"

# Gems installed with --user-install land here; put them on PATH so `bundle`
# resolves without needing root.
GEM_USER_BIN="$(ruby -e 'print Gem.user_dir')/bin"
export PATH="$GEM_USER_BIN:$PATH"

if ! command -v bundle >/dev/null; then
  say "Installing bundler (user-local, no sudo needed)"
  gem install --user-install --no-document bundler
fi

# --- Dependencies -----------------------------------------------------------

# Keep gems inside the repo (vendor/ is gitignored) so nothing needs root.
bundle config set --local path vendor/bundle >/dev/null

if ! bundle check >/dev/null 2>&1; then
  # Native extensions (nokogiri, bigdecimal, racc, ...) need the Ruby headers
  # and a compiler. Fail with the fix rather than a wall of mkmf output.
  HDR_DIR="$(ruby -e 'require "rbconfig"; print RbConfig::CONFIG["rubyhdrdir"] || ""')"
  if [[ -z "$HDR_DIR" || ! -f "$HDR_DIR/ruby.h" ]]; then
    cat >&2 <<'EOF'
ERROR: Ruby development headers are missing, so native gems cannot build.

Install them once (needs your password):

    sudo apt install -y build-essential ruby-dev zlib1g-dev

then re-run ./serve.sh
EOF
    exit 1
  fi

  say "Installing gems into vendor/bundle (first run takes a few minutes)"
  bundle install
fi

# --- Ports ------------------------------------------------------------------

# Jekyll's livereload default is 35729, i.e. 4000 + 31729. Deriving it from the
# HTTP port the same way means `--port 4001` also moves livereload out of the
# way, so a second instance doesn't collide with the first.
[[ -n "$LIVERELOAD_PORT" ]] || LIVERELOAD_PORT=$((PORT + 31729))

port_busy() {
  if command -v ss >/dev/null; then
    ss -ltn "sport = :$1" 2>/dev/null | grep -q LISTEN
  else
    (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3<&-; return 0; } || return 1
  fi
}

for p in "$PORT" "$LIVERELOAD_PORT"; do
  if port_busy "$p"; then
    cat >&2 <<EOF
ERROR: port $p is already in use — most likely ./serve.sh is already running.

  * Reuse it:            open http://localhost:$PORT (it picks up file edits by itself)
  * Stop it:             Ctrl-C in its terminal, or  pkill -f 'jekyll serve'
  * Run a second copy:   ./serve.sh --port $((PORT + 1))
EOF
    exit 1
  fi
done

# --- Serve ------------------------------------------------------------------

if [[ $CLEAN -eq 1 ]]; then
  say "Cleaning _site/ and .jekyll-cache/"
  bundle exec jekyll clean
fi

if [[ $BUILD_ONLY -eq 1 ]]; then
  say "Building into _site/"
  exec bundle exec jekyll build "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
fi

say "Serving on http://localhost:$PORT  (Ctrl-C to stop)"
say "Edits to pages reload automatically; changes to _config.yml need a restart."

# -l enables livereload; -H localhost keeps it on the loopback interface, which
# is what VSCode's PORTS panel forwards to your machine. Forward $LIVERELOAD_PORT
# too if the browser stops auto-refreshing.
exec bundle exec jekyll serve -l -H localhost -P "$PORT" \
  --livereload-port "$LIVERELOAD_PORT" \
  "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
