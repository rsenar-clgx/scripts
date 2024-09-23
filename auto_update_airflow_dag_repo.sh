#!/bin/sh
# =====================================
# get TIER from CLGX_ENVIRONMENT enviroment variable
TIER=$CLGX_ENVIRONMENT
DBT_PROJECTS_DIR="dags/dbt_projects"
TEMP_DIR="/tmp"

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
cd $TEMP_DIR
# clean up directory
rm -rf $TEMP_DIR/$SRC_TIER/$DBT_PROJECT
# e.g. git clone --branch dev git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git /tmp/idap_data_pipelines_us-commercialprefill-standardization
git clone --branch $SRC_TIER $URL_DBT_PROJECT $TEMP_DIR/$SRC_TIER/$DBT_PROJECT
cd $TEMP_DIR/$SRC_TIER/$DBT_PROJECT
# It returns the most recent tag in the current branch's history that matches the pattern
# e.g. v0.0.9
TAG=`git describe --abbrev=0 --tags --match="v[0-9]*" 2>/dev/null`
echo "=== latest tag: $TAG from [$SRC_TIER] tier"
# clean up directory
cd $TEMP_DIR
rm -rf $TEMP_DIR/$SRC_TIER/$DBT_PROJECT

# update version in deployment_manifest.yml with latest tag
if [ "$TIER" != "develop" ]; then
    # clean up directory
    cd $TEMP_DIR
    rm -rf $TEMP_DIR/$TIER/$DBT_PROJECT
    git clone --branch $TIER $URL_DBT_PROJECT $TEMP_DIR/$TIER/$DBT_PROJECT
    cd $TEMP_DIR/$TIER/$DBT_PROJECT
    yq eval ".$TIER.version = \"$TAG\"" -i deployment_manifest.yml
    git commit -am "update [$TIER] tier version in deployment_manifest.yml to [$TAG]"
    echo "=== update [$TIER] tier version in deployment_manifest.yml to [$TAG]"
    git push origin $TIER
    # clean up directory
    cd $TEMP_DIR
    rm -rf $TEMP_DIR/$TIER/$DBT_PROJECT
fi

# =====================================
# This command extracts the first part of the domain name (the subdomain or the main part of the domain) from the URL_AIRFLOW_DAGS variable
# e.g. git@github.com:corelogic-private/technology_ops_us-library-airflow_etl_dag_tpl.git
# AIRFLOW_DAGS=technology_ops_us-library-airflow_etl_dag_tpl
AIRFLOW_DAGS=$(echo "$URL_AIRFLOW_DAGS" | cut -d'/' -f2 | cut -d'.' -f1)
# clean up directory
cd $TEMP_DIR
rm -rf $TEMP_DIR/$TIER/$AIRFLOW_DAGS
# e.g. git clone --branch dev git@github.com:corelogic-private/technology_ops_us-library-airflow_etl_dag_tpl.git /tmp/technology_ops_us-library-airflow_etl_dag_tpl
git clone --branch $TIER $URL_AIRFLOW_DAGS $TEMP_DIR/$TIER/$AIRFLOW_DAGS
cd $TEMP_DIR/$TIER/$AIRFLOW_DAGS

# sync dbt_project_parser.py file
if [ "$TIER" = "int" ]; then
    # git checkout origin/develop -- .gitignore
    git checkout origin/develop -- dags/dbt_project_parser.py
    git commit -am "syncing dags/dbt_project_parser.py from [develop] branch"
elif [ "$TIER" = "prd" ]; then
    # git checkout origin/int -- .gitignore
    git checkout origin/int -- dags/dbt_project_parser.py
    git commit -am "syncing dags/dbt_project_parser.py from [int] branch"
fi

DBT_PROJECT_DIR="$TEMP_DIR/$TIER/$AIRFLOW_DAGS/$DBT_PROJECTS_DIR/$DBT_PROJECT"
# check is file exists and is a directory, returns true if exists
if [ -d "$DBT_PROJECT_DIR" ]; then
    echo "=== UPDATE [$DBT_PROJECTS_DIR/$DBT_PROJECT] dbt project in [$TIER] tier with [$TAG] tag"
    git subtree pull -m "UPDATE [$DBT_PROJECTS_DIR/$DBT_PROJECT] dbt project in [$TIER] tier with [$TAG] tag" --prefix=$DBT_PROJECTS_DIR/$DBT_PROJECT $URL_DBT_PROJECT $TAG --squash
    git push origin $TIER
else
    echo "=== ADD [$DBT_PROJECT] dbt project to [$DBT_PROJECTS_DIR] in [$TIER] tier with [$TAG] tag"
    git subtree add -m "ADD [$DBT_PROJECT] dbt project to [$DBT_PROJECTS_DIR] in [$TIER] tier with [$TAG] tag" --prefix=$DBT_PROJECTS_DIR/$DBT_PROJECT $URL_DBT_PROJECT $TAG --squash
    git push origin $TIER
fi
# clean up directory
cd $TEMP_DIR
rm -rf $TEMP_DIR/$TIER/$AIRFLOW_DAGS
