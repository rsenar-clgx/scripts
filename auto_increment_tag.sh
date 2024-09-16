#!/bin/sh
# =====================================
# get TIER from CLGX_ENVIRONMENT enviroment variable
TIER=$CLGX_ENVIRONMENT
TEMP_DIR="/tmp"

# URL_DBT_PROJECT="git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git"
URL_DBT_PROJECT="git@github.com:rsenar-clgx/ce_standardization_test.git"

echo "================================================"
echo " triggering auto_increment_tag script "
echo "================================================"
# test operator to trigger script if dev environment only
if [ "$TIER" != "dev" ]; then
    echo "=== tag auto increment unavailable in [$TIER], enabled ONLY for [dev] tier..."
    exit 0
fi

# This command extracts the first part of the domain name (the subdomain or the main part of the domain) from the URL_DBT_PROJECT variable
# e.g. git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git
# DBT_PROJECT=idap_data_pipelines_us-commercialprefill-standardization
DBT_PROJECT=$(echo "$URL_DBT_PROJECT" | cut -d'/' -f2 | cut -d'.' -f1)
echo "=== auto increment tag for [$URL_DBT_PROJECT] in [$TIER] environment"
rm -rf $TEMP_DIR/$DBT_PROJECT
# e.g. git clone --branch dev git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git /tmp/idap_data_pipelines_us-commercialprefill-standardization
git clone --branch $TIER $URL_DBT_PROJECT $TEMP_DIR/$DBT_PROJECT
cd $TEMP_DIR/$DBT_PROJECT

# It returns the most recent tag in the current branch's history that matches the pattern
# e.g. v1.2.3
VERSION=`git describe --abbrev=0 --tags --match="v[0-9]*" 2>/dev/null`
# get semantic version components
V="v" # prefix
VNUM1=$(echo "$VERSION" | cut -d"." -f1 | sed 's/v//') # 1
VNUM2=$(echo "$VERSION" | cut -d"." -f2) # 2
VNUM3=$(echo "$VERSION" | cut -d"." -f3) # 3

# Check for #major or #minor in commit message prefix and increment the relevant version number
MAJOR=`git log --format=%B -n 1 HEAD | grep 'major:'` # output: ""
MINOR=`git log --format=%B -n 1 HEAD | grep 'feat:'` # output: ""
PATCH=`git log --format=%B -n 1 HEAD | grep 'fix:'` # output: "fix: update dbt_project.yml"

# test operator that checks if the string $MAJOR is not empty, then increment MAJOR value
if [ "$MAJOR" ]; then
    VNUM1=$((VNUM1+1)) # e.g. 0 -> 1
    VNUM2=0
    VNUM3=0
# test operator that checks if the string $MINOR is not empty, then increment MINOR value
elif [ "$MINOR" ]; then
    VNUM2=$((VNUM2+1)) # e.g. 0 -> 1
    VNUM3=0
# test operator that checks if the string $PATCH is not empty, then increment PATCH value
elif [ "$PATCH" ]; then
    VNUM3=$((VNUM3+1)) # e.g. 9 -> 10
fi

# create new tag
# e.g. v1.2.4
NEW_TAG="$V$VNUM1.$VNUM2.$VNUM3"

# validate NEW_TAG format, overide to default values if invalid format
if [ $NEW_TAG = "v..1" ]; then
    NEW_TAG="v0.0.1"
elif [ $NEW_TAG = "v.1.0" ]; then
    NEW_TAG="v0.1.0"
fi

# retrieve the full commit hash of the latest commit on the current branch
# e.g. b23ab3c87f47f58e19b0a3a7e9d57c456f9a36bd
GIT_COMMIT=`git rev-parse HEAD`
# attempts to find the smallest tag or reference that contains the specified commit hash and silently discards any error messages that might occur
NEEDS_TAG=`git describe --contains $GIT_COMMIT 2>/dev/null`

# test operator that checks if the string is empty. Returns true if the string has a length of 0 (i.e., it is empty)
if [ -z "$NEEDS_TAG" ]; then
    echo "=== updating from [$VERSION] to [$NEW_TAG] in [$TIER] environment (Ignoring fatal:cannot describe - this means commit is untagged)"
    # generate new tag: v0.0.10
    git tag $NEW_TAG
    git push --tags
else
    echo "=== SKIPPING: already a tag on this commit"
fi

# clean up temp directories
rm -rf $TEMP_DIR/$DBT_PROJECT
