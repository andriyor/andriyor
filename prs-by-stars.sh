#!/usr/bin/env bash
# Markdown table of the repos with >100 stars I've sent PRs to, with links to the PRs.
# Usage: ./prs-by-stars.sh [extra search qualifiers] > prs.md, e.g. ./prs-by-stars.sh is:merged > prs.md
set -euo pipefail

gh api graphql --paginate --slurp -f q="author:@me is:pr -user:@me $*" -f query='
query($q: String!, $endCursor: String) {
  search(query: $q, type: ISSUE, first: 100, after: $endCursor) {
    pageInfo { hasNextPage endCursor }
    nodes { ... on PullRequest { number url repository { nameWithOwner url stargazerCount } } }
  }
}' | jq -r '
  [.[].data.search.nodes[]] | group_by(.repository.nameWithOwner)
  | sort_by(-.[0].repository.stargazerCount) | map(select(.[0].repository.stargazerCount > 100))
  | "| Repo | Stars | PRs |", "|---|---|---|",
    (.[] | "| [\(.[0].repository.nameWithOwner)](\(.[0].repository.url)) | \(.[0].repository.stargazerCount) | \(sort_by(.number) | map("[#\(.number)](\(.url))") | join(" ")) |")'
