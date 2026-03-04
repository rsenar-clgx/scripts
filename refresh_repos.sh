#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=~/workspace
BRANCHES=(develop dev int preprod prd master)

repos=(
    idap_data_pipelines_us-commercialprefill-analytics
    idap_data_pipelines_us-commercialprefill-commercial_xref
    idap_data_pipelines_us-commercialprefill-constructor
    idap_data_pipelines_us-commercialprefill-constructor_api
    idap_data_pipelines_us-commercialprefill-constructor_ds_models
    idap_data_pipelines_us-commercialprefill-ds_models
    idap_data_pipelines_us-commercialprefill-ds_models_uc
    idap_data_pipelines_us-commercialprefill-multi_modal_dispatcher
    idap_data_pipelines_us-commercialprefill-sandbox
    idap_data_pipelines_us-commercialprefill-standardization
    idap_data_pipelines_us-commercialprefill-testing
    idap_data_pipelines_us-commercialprefill-vexcel_ief
    idap_data_pipelines_us-firmographics-analytics
    idap_data_pipelines_us-firmographics-constructor
    idap_data_pipelines_us-firmographics-standardization
    idap_data_pipelines_us-panoramiq-gce_config
    idap_data_pipelines_us-panoramiq-gce_controller
    idap_data_pipelines_us-panoramiq-gce_dbt
    technology_ops_us-library-airflow_etl_dag_tpl
)

refresh_repo() {
    local repo="$1"
    echo ">>>>>>>>>>>>>>>>>>>> Refreshing $repo"
    cd "$WORKSPACE/$repo"
    for branch in "${BRANCHES[@]}"; do
        git co "$branch" && git pull -r
    done
    git co dev
}

for repo in "${repos[@]}"; do
    refresh_repo "$repo"
done

cd "$WORKSPACE"
