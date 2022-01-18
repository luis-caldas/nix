#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import subprocess
import urllib.request

USER_NAME="luis-caldas"
REPOS_PREFIX="my"
REPOS_BRANCH="master"


def print_item(size, name, commit, hash):
    print( ( " %%%ds - %%s - %%s" % size ) % (name, commit, hash) )


def main():

    # Create URL
    reposURL = "https://api.github.com/users/%s/repos" % USER_NAME

    # Get all repos
    repos = json.load(urllib.request.urlopen(reposURL))

    # Extract repo names
    cleanNames = [each["name"] for each in repos if each["name"].startswith(REPOS_PREFIX)]

    # Get length of biggest string
    bigLen = len(max(cleanNames, key=len))

    # Create header
    print_item(bigLen, "Name", "Commit", "SHA256")

    # Iterate and get commits
    for eachProject in cleanNames:

        # Get commit info
        projURL = "https://api.github.com/repos/%s/%s/branches" % (USER_NAME, eachProject)

        # Extract chosen branch and last commit hash
        chosenBranch = [each for each in json.load(urllib.request.urlopen(projURL)) if each["name"] == REPOS_BRANCH].pop()
        lastCommitHash = chosenBranch["commit"]["sha"]

        # Generate hash command
        hashCommand = "nix-prefetch-url --unpack https://github.com/%s/%s/archive/%s.tar.gz" % (USER_NAME, eachProject, lastCommitHash)

        # Run command and get output
        shaHash = subprocess.run(hashCommand.split(" "), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout.decode("utf-8").strip("\n")

        # Print item
        print_item(bigLen, eachProject, lastCommitHash, shaHash)


if __name__ == "__main__":
    main()

