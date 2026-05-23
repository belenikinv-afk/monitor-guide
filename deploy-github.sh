#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
cd "$(dirname "$0")"

if ! gh auth status &>/dev/null; then
  echo "Сначала войдите в GitHub:"
  echo "  gh auth login -h github.com -p https -s repo --web"
  exit 1
fi

USER=$(gh api user -q .login)
REPO_NAME="${1:-monitor-guide}"

if gh repo view "$USER/$REPO_NAME" &>/dev/null; then
  echo "Репозиторий $USER/$REPO_NAME уже есть, пушим..."
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/$USER/$REPO_NAME.git"
  git push -u origin main
else
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push --description "Гид по мониторам 27-32″"
fi

gh api -X POST "repos/$USER/$REPO_NAME/pages" --input - <<EOF || \
gh api -X PUT "repos/$USER/$REPO_NAME/pages" --input - <<EOF
{
  "build_type": "legacy",
  "source": { "branch": "main", "path": "/" }
}
EOF

URL="https://$USER.github.io/$REPO_NAME/"
echo ""
echo "Сайт (через 1–3 мин): $URL"
printf '%s\n' "$URL" > PUBLIC_LINK.txt
