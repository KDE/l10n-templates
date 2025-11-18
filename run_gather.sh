#! /bin/sh
#
# SPDX-FileCopyrightText: 2025 Johnny Jazeix <jazeix@gmail.com>
#
# SPDX-License-Identifier: MIT

export PATH=$PATH:$PWD/pology/bin;

today=`date +"%g%m%d"`
# We can only download the latest if we assume it's always the same order and we know which one it is
for branch in trunk_l10n-kf6 trunk_l10n-kf5 branches_stable_l10n-kf6 branches_stable_l10n-kf5; do
    logfile=$today.$branch
    wget -q https://logs.l10n.kde.org/$logfile
    if grep -q "@@@ branch" $logfile; then
        echo "Branch $branch processed by scripty"
    else
        echo "Branch $branch not processed yet, aborting the gather"
        # Is it possible to reschedule today? We probably need a better trigger than a specific hour
        exit 1
    fi
    rm -f $logfile
done

cd l10n-support

for M in messages docmessages; do
    posummit scripts/${M}.summit.gather templates gather --create
done

cd -

git add summit
anyAddedOrDeletedFiles=`git diff --cached --name-status --diff-filter=ADR summit/`
if [ ! -z "$anyAddedOrDeletedFiles" ]; then
    echo "Files have been added or removed, do nothing."
    echo "git diff --cached --name-status --diff-filter=ADR:"
    echo "$anyAddedOrDeletedFiles"
    exit 1
fi

anyModifiedFiles=`git diff --cached --name-status --diff-filter=M summit/`
if [ -z "$anyModifiedFiles" ]; then
    echo "No modified files, do nothing."
    exit 0
fi

echo "Files updated, pushing the changes."
git commit -m "GIT_SILENT: gather"
#git push -o ci.skip origin HEAD:$CI_COMMIT_REF_NAME
exit 0
