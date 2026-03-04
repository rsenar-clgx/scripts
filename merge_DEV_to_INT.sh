#!/bin/bash

WORKSPACE=~/workspace
SLEEP_DURATION=60  # seconds between each repo

REPOS=(
  idap_data_pipelines_us-commercialprefill-analytics
  idap_data_pipelines_us-commercialprefill-commercial_xref
  idap_data_pipelines_us-commercialprefill-constructor
  idap_data_pipelines_us-commercialprefill-constructor_api
  idap_data_pipelines_us-commercialprefill-constructor_ds_models
  idap_data_pipelines_us-commercialprefill-ds_models
  idap_data_pipelines_us-commercialprefill-ds_models_uc
  idap_data_pipelines_us-commercialprefill-sandbox
  idap_data_pipelines_us-commercialprefill-standardization
  idap_data_pipelines_us-commercialprefill-testing
  idap_data_pipelines_us-commercialprefill-vexcel_ief
  idap_data_pipelines_us-firmographics-analytics
  idap_data_pipelines_us-firmographics-constructor
  idap_data_pipelines_us-firmographics-standardization
)

update_repo() {
  local repo="$1"
  echo ">>>>>>>>>>>>>>>>>>>> Processing $repo..."
  cd "$WORKSPACE/$repo" || { echo "ERROR: Cannot cd into $repo, skipping."; return 1; }
  git co dev \
    && git pull -r \
    && git co int \
    && git pull -r \
    && git merge dev --no-edit \
    && git push \
    || echo "ERROR: Failed on $repo"
}

for i in "${!REPOS[@]}"; do
  update_repo "${REPOS[$i]}"
  # Skip sleep after the last repo
  [[ $i -lt $(( ${#REPOS[@]} - 1 )) ]] && sleep "$SLEEP_DURATION"
done

cd "$WORKSPACE"
