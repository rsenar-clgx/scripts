#!/bin/sh
# =====================================
# get TIER from CLGX_ENVIRONMENT enviroment variable
TIER=$CLGX_ENVIRONMENT
URL_DBT_PROJECT=""git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git""
URL_AIRFLOW_DAGS="git@github.com:corelogic-private/technology_ops_us-library-airflow_etl_dag_tpl.git"
DBT_PROJECTS_DIR="dags/dbt_projects"

# =====================================
# Update DBT project in Airflow Dag Repo
# =====================================
if [ "$TIER" = "dev" ]; then
    echo "================================================"
    echo " triggering auto_update_airflow_dag_repo script "
    echo "================================================"
    DBT_PROJECT=$(echo "$URL_DBT_PROJECT" | cut -d'/' -f2 | cut -d'.' -f1)
    echo "=== get latest tag for [$URL_DBT_PROJECT] in [$TIER] environment"
    rm -rf /tmp/$DBT_PROJECT
    git clone --branch $TIER $URL_DBT_PROJECT /tmp/$DBT_PROJECT
    cd /tmp/$DBT_PROJECT
    TAG=`git describe --abbrev=0 --tags --match="v[0-9]*"`
    echo "=== latest tag: $TAG"

    # =====================================
    # map dev == develop for git@github.com:rsenar-clgx/airflow-repo-test.git
    TIER="develop"

    AIRFLOW_DAGS=$(echo "$URL_AIRFLOW_DAGS" | cut -d'/' -f2 | cut -d'.' -f1)
    rm -rf /tmp/$AIRFLOW_DAGS
    git clone --branch $TIER $URL_AIRFLOW_DAGS /tmp/$AIRFLOW_DAGS
    cd /tmp/$AIRFLOW_DAGS

    DBT_PROJECT_DIR="/tmp/$AIRFLOW_DAGS/$DBT_PROJECTS_DIR/$DBT_PROJECT"
    if [ -d "$DBT_PROJECT_DIR" ]; then
        echo "=== update [$DBT_PROJECTS_DIR/$DBT_PROJECT] project in [$URL_AIRFLOW_DAGS] to [$TAG] tag in [$TIER] environment"
        git subtree pull -m "update $DBT_PROJECT to [$TAG] in [$TIER] environment" --prefix=$DBT_PROJECTS_DIR/$DBT_PROJECT $URL_DBT_PROJECT $TAG --squash
        git push origin $TIER
    else
        echo "=== add [$DBT_PROJECTS_DIR/$DBT_PROJECT] project to [$URL_AIRFLOW_DAGS] from [$URL_DBT_PROJECT] in [$TIER] environment with [$TAG] tag"
        git subtree add --prefix=$DBT_PROJECTS_DIR/$DBT_PROJECT $URL_DBT_PROJECT $TAG --squash
        git push origin $TIER
    fi

    # =====================================
    # clean up temp directories
    rm -rf /tmp/$DBT_PROJECT
    rm -rf /tmp/$AIRFLOW_DAGS
fi
