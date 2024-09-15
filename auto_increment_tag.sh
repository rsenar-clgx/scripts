#!/bin/sh
# =====================================
# get TIER from CLGX_ENVIRONMENT enviroment variable
TIER=$CLGX_ENVIRONMENT

URL_DBT_PROJECT="git@github.com:corelogic-private/idap_data_pipelines_us-commercialprefill-standardization.git"
# URL_DBT_PROJECT="git@github.com:rsenar-clgx/ce_standardization_test.git"

# =====================================
# Auto Increment Git Tag
# =====================================
# run in dev environment only
if [ "$TIER" != "dev" ]; then
    exit 0
fi

echo "======================================"
echo " triggering auto_increment_tag script "
echo "======================================"
DBT_PROJECT=$(echo "$URL_DBT_PROJECT" | cut -d'/' -f2 | cut -d'.' -f1)
echo "=== auto increment tag for [$URL_DBT_PROJECT] in [$TIER] environment"
rm -rf /tmp/$DBT_PROJECT
git clone --branch $TIER $URL_DBT_PROJECT /tmp/$DBT_PROJECT
cd /tmp/$DBT_PROJECT

# get highest tag number
VERSION=`git describe --abbrev=0 --tags --match="v[0-9]*"`
V=""
if [[ $VERSION =~ "v" ]]; then
    V="v"
fi
#get number parts and increase last one by 1
VNUM1=$(echo "$VERSION" | cut -d"." -f1)
VNUM2=$(echo "$VERSION" | cut -d"." -f2)
VNUM3=$(echo "$VERSION" | cut -d"." -f3)
VNUM1=`echo $VNUM1 | sed 's/v//'`

# Check for #major or #minor in commit message and increment the relevant version number
MAJOR=`git log --format=%B -n 1 HEAD | grep 'major:'`
MINOR=`git log --format=%B -n 1 HEAD | grep 'feat:'`
PATCH=`git log --format=%B -n 1 HEAD | grep 'fix:'`

if [ "$MAJOR" ]; then
    # echo "Update MAJOR version"
    VNUM1=$((VNUM1+1))
    VNUM2=0
    VNUM3=0
elif [ "$MINOR" ]; then
    # echo "Update MINOR version"
    VNUM2=$((VNUM2+1))
    VNUM3=0
elif [ "$PATCH" ]; then
    # echo "Update PATCH version"
    VNUM3=$((VNUM3+1))
fi

# create new tag
NEW_TAG="$V$VNUM1.$VNUM2.$VNUM3"

# validate tag format
if [ $NEW_TAG = "..1" ]; then
    NEW_TAG="v0.0.1"
elif [ $NEW_TAG = ".1.0" ]; then
    NEW_TAG="v0.1.0"
fi

# get current hash and see if it already has a tag
GIT_COMMIT=`git rev-parse HEAD`
NEEDS_TAG=`git describe --contains $GIT_COMMIT 2>/dev/null`

# only tag if no tag already (would be better if the git describe command above could have a silent option)
if [ -z "$NEEDS_TAG" ]; then
    echo "=== updating from [$VERSION] to [$NEW_TAG] in [$TIER] environment (Ignoring fatal:cannot describe - this means commit is untagged)"
    git tag $NEW_TAG
    git push --tags
else
    echo "=== SKIPPING: already a tag on this commit"
fi

# clean up temp directories
rm -rf /tmp/$DBT_PROJECT
