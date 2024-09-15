#!/bin/sh
# =====================================
# get TIER from CLGX_ENVIRONMENT enviroment variable
TIER=$CLGX_ENVIRONMENT
DBT_PROJECTS_DIR="dags/dbt_projects"
ROOT_DIR="/tmp"

# URL_DBT_PROJECT="git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git"
# URL_AIRFLOW_DAGS="git@github.com:corelogic-private/technology_ops_us-library-airflow_etl_dag_tpl.git"
URL_DBT_PROJECT="git@github.com:rsenar-clgx/ce_standardization_test.git"
URL_AIRFLOW_DAGS="git@github.com:rsenar-clgx/airflow_dags_repo_test.git"

echo "================================================"
echo " triggering auto_update_airflow_dag_repo script "
echo "================================================"
# test operator to setup SRC_TIER and TIER variables for corresponding tier
# exit if tier value is invalid
if [ "$TIER" = "dev" ]; then
    SRC_TIER=$TIER
    TIER="develop"
elif [ "$TIER" = "int" ]; then
    SRC_TIER="dev"
elif [ "$TIER" = "prd" ]; then
    SRC_TIER="int"
else
    echo "=== unable to auto update dbt project in airflow dag repo, invalid [$TIER] tier..."
    exit 0
fi

# This command extracts the first part of the domain name (the subdomain or the main part of the domain) from the URL_DBT_PROJECT variable
# e.g. git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git
# DBT_PROJECT=idap_data_pipelines_us-commercialprefill-standardization
DBT_PROJECT=$(echo "$URL_DBT_PROJECT" | cut -d'/' -f2 | cut -d'.' -f1)
echo "=== get latest tag for [$URL_DBT_PROJECT] in [$SRC_TIER] environment"
rm -rf $ROOT_DIR/$DBT_PROJECT
# e.g. git clone --branch dev git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git /tmp/idap_data_pipelines_us-commercialprefill-standardization
git clone --branch $SRC_TIER $URL_DBT_PROJECT $ROOT_DIR/$DBT_PROJECT
cd $ROOT_DIR/$DBT_PROJECT
# It returns the most recent tag in the current branch's history that matches the pattern
# e.g. v0.0.9
TAG=`git describe --abbrev=0 --tags --match="v[0-9]*"`
echo "=== latest tag: $TAG"

# =====================================
# This command extracts the first part of the domain name (the subdomain or the main part of the domain) from the URL_AIRFLOW_DAGS variable
# e.g. git@github.com:corelogic-private/technology_ops_us-library-airflow_etl_dag_tpl.git
# AIRFLOW_DAGS=technology_ops_us-library-airflow_etl_dag_tpl
AIRFLOW_DAGS=$(echo "$URL_AIRFLOW_DAGS" | cut -d'/' -f2 | cut -d'.' -f1)
rm -rf $ROOT_DIR/$AIRFLOW_DAGS
# e.g. git clone --branch dev git@github.com:corelogic-private/technology_ops_us-library-airflow_etl_dag_tpl.git /tmp/technology_ops_us-library-airflow_etl_dag_tpl
git clone --branch $TIER $URL_AIRFLOW_DAGS $ROOT_DIR/$AIRFLOW_DAGS
cd $ROOT_DIR/$AIRFLOW_DAGS

DBT_PROJECT_DIR="$ROOT_DIR/$AIRFLOW_DAGS/$DBT_PROJECTS_DIR/$DBT_PROJECT"
# check is file exists and is a directory, returns true if exists
if [ -d "$DBT_PROJECT_DIR" ]; then
    echo "=== UPDATE: [$DBT_PROJECTS_DIR/$DBT_PROJECT] dbt project in [$TIER] environment with [$TAG] tag"
    git subtree pull -m "UPDATE: [$DBT_PROJECTS_DIR/$DBT_PROJECT] dbt project in [$TIER] environment with [$TAG] tag" --prefix=$DBT_PROJECTS_DIR/$DBT_PROJECT $URL_DBT_PROJECT $TAG --squash
    git push origin $TIER
else
    echo "=== ADD: [$DBT_PROJECT] dbt project to [$DBT_PROJECTS_DIR] in [$TIER] environment with [$TAG] tag"
    git subtree add -m "ADD: [$DBT_PROJECT] dbt project to [$DBT_PROJECTS_DIR] in [$TIER] environment with [$TAG] tag" --prefix=$DBT_PROJECTS_DIR/$DBT_PROJECT $URL_DBT_PROJECT $TAG --squash
    git push origin $TIER
fi

# =====================================
# clean up temp directories
rm -rf $ROOT_DIR/$DBT_PROJECT
rm -rf $ROOT_DIR/$AIRFLOW_DAGS
