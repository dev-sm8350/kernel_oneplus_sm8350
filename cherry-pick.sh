#!/bin/bash
#
# EXAMPLES
#   ./cherry-pick.sh <commit-hash>
#

# Cherry-pick provided commit with signature
git cherry-pick "$@" -x -s -m 1

# Verify if cherry-pick was successful
if [ $? -eq 0 ]; then 

    # Add a Signed-off-by line in the commit message, if not present
    commit_file=$(git rev-parse --git-dir)/COMMIT_EDITMSG
    if ! grep -qs "^Signed-off-by:" "$commit_file"; then
        echo -e "\nSigned-off-by: TogoFire <togofire@mailfence.com>\n" >> "$commit_file"
    fi

    # Show a success message and exit
    echo "Cherry-pick successful!"
    exit 0

else 

    # Show an error message and exit
    echo "Cherry-pick failed"
    exit 1

fi
