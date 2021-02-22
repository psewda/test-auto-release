#!/bin/bash

# file having current version
version_file="$(pwd)/version.go"

# get latest git tag
git_tag=$(git describe --tags --abbrev=0 2>&1)
if [ $? -ne 0 ]; then
    echo "error: git tag not found [$git_tag]"
    exit 1
fi
echo "latest git tag => $git_tag" 

# remove the 'v' prefix
if [[ $git_tag == v* ]]; then
    git_tag=$(echo $git_tag | cut -d "v" -f 2)
fi

# calculate bump type
bump_type=$(auto version 2>&1)
if [ $? -ne 0 ]; then
    echo "error: bump type calculation failed [$bump_type]"
    exit 1
fi
echo "calculated bump type => " $bump_type

if [[ $bump_type == @(major|minor|patch) ]]; then
    # bump the version
    new_version=$($(pwd)/ci/semver bump $bump_type $git_tag 2>&1)
    if [ $? -ne 0 ]; then
        echo "error: version bump failed [$new_version]"
        exit 1
    fi
    echo "new version after bump => " $new_version

    # update version in version.go file
    find="var Version =.*"
    replace="var Version = \"$new_version\""
    updated=$(sed -i "s/$find/$replace/w /dev/stdout" $version_file)
    if [ -z "$updated" ]; then
        echo "error: version not updated in version.go"
        exit 1
    fi
    echo "version.go updated with new version $new_version"

    # do git commit
    git add $version_file
    git commit -m "ci: bump version to: $new_version [skip ci]"
    echo "committed version.go"
fi
