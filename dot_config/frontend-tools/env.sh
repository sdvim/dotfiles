# Sourced by the managed frontend launchers; no login-shell setup is required.
PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
export PATH
FRONTEND_MISE=$(command -v mise) || { echo 'frontend tools: install mise first' >&2; exit 1; }
export FRONTEND_MISE
FRONTEND_NODE=$("$FRONTEND_MISE" which node --tool node@22) || exit 1
PATH="$(dirname "$FRONTEND_NODE"):$PATH"
export PATH
NO_UPDATE_NOTIFIER=1
export NO_UPDATE_NOTIFIER

frontend_java() {
  JAVA_HOME=$("$FRONTEND_MISE" where java@temurin-21.0.12+8.0.LTS) || exit 1
  PATH="$JAVA_HOME/bin:$PATH"
  export JAVA_HOME PATH
}
