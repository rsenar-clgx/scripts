#!/bin/sh
# =====================================
# get TIER from CLGX_ENVIRONMENT enviroment variable
TIER="dev"
TAG="v0.1.0"
URL_DBT_PROJECT=""git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git""
URL_AIRFLOW_DAGS="git@github.com:corelogic-private/technology_ops_us-library-airflow_etl_dag_tpl.git"
DBT_PROJECTS_DIR="dags/dbt_projects"

if [[ "$TIER" == "dev" || "$TIER" == "int" || "$TIER" == "prd" ]]; then
    # =====================================
    TIER="develop"
    AIRFLOW_DAGS=$(echo "$URL_AIRFLOW_DAGS" | cut -d'/' -f2 | cut -d'.' -f1)
    rm -rf /tmp/$AIRFLOW_DAGS
    git clone --branch $TIER $URL_AIRFLOW_DAGS /tmp/$AIRFLOW_DAGS
    cd /tmp/$AIRFLOW_DAGS

    DBT_PROJECT=$(echo "$URL_DBT_PROJECT" | cut -d'/' -f2 | cut -d'.' -f1)
    echo "=== update [$DBT_PROJECTS_DIR/$DBT_PROJECT] project in [$URL_AIRFLOW_DAGS] to [$TAG] tag in [$TIER] environment"
    git subtree pull -m "update $DBT_PROJECT to $TAG in $TIER environment" --prefix=$DBT_PROJECTS_DIR/$DBT_PROJECT $URL_DBT_PROJECT $TAG --squash
    git push origin $TIER

    # =====================================
    # clean up temp directories
    rm -rf /tmp/$AIRFLOW_DAGS
else
    echo "Invalid environment $TIER..."
fi
