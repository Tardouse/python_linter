#!/bin/bash

URL="https://pypi.org/pypi/ruff/json"
PYPROJECT_PATH="./pyproject.json"
PRE_COMMIT_PATH="./.pre-commit-config.yaml"
CURRENT_VERSION=$(jq -r '.project.dependencies.ruff' $PYPROJECT_PATH)
ALL_VERSIONS=$(curl -s "$URL" | jq -r '.releases | keys | .[]' | sort -V)

TARGET_VERSIONS=$(echo "$ALL_VERSIONS" | awk -v current_version="$CURRENT_VERSION" '$0 > current_version')

for version in $TARGET_VERSIONS; do
	# update pyproject.json
	jq '.project.dependencies.ruff = $version' --arg version $version $PYPROJECT_PATH > tmp.$$.json && mv tmp.$$.json $PYPROJECT_PATH

	# update .pre-commit-config.yaml
    sed -i "s/rev: v[0-9]\+\.[0-9]\+\.[0-9]\+/rev: v$version/" "$PRE_COMMIT_PATH"
done

# commit Git
if [[ -n "$(git status -s)" ]]; then
	git add "$PYPROJECT_PATH" "$PRE_COMMIT_PATH"
	git commit -m "Mirror: $version"
	git tag "v$version"
else
	echo "No change for version v$version"
fi
