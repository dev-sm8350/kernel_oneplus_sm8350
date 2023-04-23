#!/bin/bash
#
# EXAMPLES
#    ./changelog.sh
#

# Setup colour for the script
purple='\033[0;35m'

# Function to show an informational message
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
    exit 1
}

# Create a filename for our changelog
CHANGELOG_FILE="changelog.txt"

# Use git log to get the most recent commits
git log -n 400 --pretty=format:"%h - %s (%an)" > $CHANGELOG_FILE

# Print the location of the changelog file
msg "${purple} Changelog saved to $CHANGELOG_FILE ${white}"

# Add commit names to the changelog file
sed -i -e "s/^/- /" $CHANGELOG_FILE
