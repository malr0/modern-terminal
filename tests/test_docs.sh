# Docs: local links resolve, agents.md has no install commands.

test_docs_local_links_resolve() {
  local doc link target
  for doc in "$REPO_DIR/README.md" "$REPO_DIR"/docs/*.md; do
    assert_file "$doc"
    while IFS= read -r link; do
      case "$link" in http*|\#*) continue ;; esac
      target="$(dirname "$doc")/${link%%#*}"
      [ -e "$target" ] || fail "$(basename "$doc") links to missing $link"
    done < <(grep -o '](\([^)]*\))' "$doc" | sed 's/^](//; s/)$//')
  done
}

test_agents_doc_has_no_install_commands() {
  local doc="$REPO_DIR/docs/agents.md" cmd
  assert_file "$doc"
  for cmd in "brew install" "npm install" "npm i " "curl " "pip install"; do
    assert_not_contains "$doc" "$cmd"
  done
}

test_readme_documents_uninstall() {
  assert_contains "$REPO_DIR/README.md" "## Uninstall"
  assert_contains "$REPO_DIR/README.md" "# modern-terminal"
  assert_contains "$REPO_DIR/README.md" "include.path"
}
