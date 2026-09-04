#!/usr/bin/env bash
# gates.sh — controles de calidad que deben pasar antes de abrir el PR.
# Muestra la salida de cada control y termina con código 1 si alguno falla.

BASE_BRANCH="${GATES_BASE_BRANCH:-main}"
FAILED=0

section() {
    echo
    echo "=================================================="
    echo "$1"
    echo "=================================================="
}

section "1/4 ruff check (src/ tests/)"
uvx ruff check src tests
if [ $? -ne 0 ]; then
    echo "--> FALLÓ: ruff encontró hallazgos."
    FAILED=1
else
    echo "--> OK: ruff sin hallazgos."
fi

section "2/4 bandit -r src (severidad media/alta)"
uvx bandit -r src --severity-level medium
if [ $? -ne 0 ]; then
    echo "--> FALLÓ: bandit encontró hallazgos de severidad media o alta."
    FAILED=1
else
    echo "--> OK: bandit sin hallazgos de severidad media o alta."
fi

section "3/4 pytest"
uv run pytest
if [ $? -ne 0 ]; then
    echo "--> FALLÓ: la suite de tests no está en verde."
    FAILED=1
else
    echo "--> OK: pytest en verde."
fi

section "4/4 Conventional Commits (${BASE_BRANCH}..HEAD)"
COMMITS=$(git log --format=%H "${BASE_BRANCH}..HEAD")
if [ -z "$COMMITS" ]; then
    echo "No hay commits nuevos respecto a ${BASE_BRANCH}."
else
    # tipos estándar de Conventional Commits, con scope y '!' de breaking change opcionales
    PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9._/-]+\))?!?: .+'
    COMMITS_FAILED=0
    while IFS= read -r sha; do
        subject=$(git log -1 --format=%s "$sha")
        if echo "$subject" | grep -Eq "$PATTERN"; then
            echo "OK   $sha  $subject"
        else
            echo "MAL  $sha  $subject"
            COMMITS_FAILED=1
        fi
    done <<< "$COMMITS"
    if [ "$COMMITS_FAILED" -ne 0 ]; then
        echo "--> FALLÓ: hay commits que no siguen el formato Conventional Commits."
        FAILED=1
    else
        echo "--> OK: todos los commits siguen el formato Conventional Commits."
    fi
fi

section "Resultado"
if [ "$FAILED" -ne 0 ]; then
    echo "Uno o más controles fallaron. No se debe abrir el PR."
    exit 1
fi

echo "Todos los controles pasaron."
exit 0
