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
    idap_data_pipelines_us-idapdataingestion-airflow_iac
    idap_data_pipelines_us-idapdataingestion-configs
    idap_data_pipelines_us-naspipeline-datascript
    idap_data_pipelines_us-onboardingpipelines-cloud_config
    idap_data_pipelines_us-onboardingpipelines-modelx_edr
    idap_data_pipelines_us-panoramiq-gce_config
    idap_data_pipelines_us-panoramiq-gce_controller
    idap_data_pipelines_us-panoramiq-gce_dbt
    idap_data_pipelines_us-platformpl-gce_bqloader
    technology_ops_us-library-pip_airflow_base
    technology_ops_us-library-pip_sdk_airflow_docker_compose
    technology_ops_us-library-pip_sdk_core
    technology_ops_us-devaccelerator-mcp_server_promptimus_primes
    technology_ops_us-devaccelerator-promptimus_primes
)

# -- Helpers --
log()       { printf '\033[33m== [Refreshing] %s\033[0m\n' "$*"; }
separator() { printf '\033[31m%s\033[0m\n' '================================================================================'; }
warn()      { printf '\033[35m!! %s\033[0m\n' "$*"; }

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

    local original_branch
    original_branch="$(git rev-parse --abbrev-ref HEAD)"

    local stashed=false
    if [[ -n "$(git status --porcelain)" ]]; then
        git stash push -u -m "refresh_repos.sh autostash $(date +%Y%m%d%H%M%S)"
        stashed=true
    fi

    while IFS= read -r branch; do
        if ! git co "$branch" || ! git pull -r; then
            warn "$repo: pull failed on branch '$branch', aborting rebase and skipping remaining branches"
            git rebase --abort 2>/dev/null || true
            break
        fi
    done < <(git for-each-ref --format='%(refname:short)' refs/heads | sort)

    git co "$original_branch"

    if [[ "$stashed" == true ]]; then
        if ! git stash pop; then
            warn "$repo: stash pop failed, resolve manually (stash left in place)"
        fi
    fi
}

for repo in "${repos[@]}"; do
    refresh_repo "$repo"
    sleep 2
done

cd "$WORKSPACE"
