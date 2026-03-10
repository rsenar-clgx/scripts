#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=~/workspace
EXCLUDED_DIRS=(
    airflow-docker
    airflow_dags_repo_test
    BMAD-METHOD
    ce_standardization_test
    commercial_express
    dbt_constructor_demo
    dbt_logs
    dbt_project_parser
    geo-ce
    logs
    notebooks
    scripts
    utilities
    idap_data_pipelines_aus-idapanzpipelines-airflow_dag
    idap_data_pipelines_us-idapdataingestion-configs
)

# -- Helpers --
log()       { printf '\033[33m== [Refreshing] %s\033[0m\n' "$*"; }
separator() { printf '\033[31m%s\033[0m\n' '================================================================================'; }

is_excluded_dir() {
    local candidate="$1"
    local excluded
    for excluded in "${EXCLUDED_DIRS[@]}"; do
        if [[ "$candidate" == "$excluded" ]]; then
            return 0
        fi
    done
    return 1
}

repos=()
while IFS= read -r repo; do
    repos+=("$repo")
done < <(
    find "$WORKSPACE" -mindepth 1 -maxdepth 1 -type d |
        while IFS= read -r dir; do
            if [ -d "$dir/.git" ]; then
                repo_name="$(basename "$dir")"
                if ! is_excluded_dir "$repo_name"; then
                    echo "$repo_name"
                fi
            fi
        done |
        sort
)

refresh_repo() {
    local repo="$1"
    separator
    log "$repo"
    separator
    cd "$WORKSPACE/$repo"
    while IFS= read -r branch; do
        git co "$branch" && git pull -r
    done < <(git for-each-ref --format='%(refname:short)' refs/heads | sort)
}

for repo in "${repos[@]}"; do
    refresh_repo "$repo"
    sleep 2
done

cd "$WORKSPACE"
