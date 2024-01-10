#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import subprocess
import urllib.request

USER_NAME    = "luis-caldas"
REPOS_PREFIX = "my"
REPOS_BRANCH = "master"

PER_PAGE = 10

COMMIT_LENGTH = 40
HASH_LENGTH   = 52

PROJECTS_FILE_NAME = "hashes.json"
NEEDED_PROJECTS_FILE = "list.json"

# Get our current location
LOCATION = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))


def main():

    # Acquire args
    reposChosen = sys.argv[1:]

    # Initialize clean name variable
    cleanNames = []

    # Import the list of my projects
    myProjects = json.load(open(os.path.join(LOCATION, NEEDED_PROJECTS_FILE), 'r'))

    # For verbose
    infoString = "[ ! ] - %s"
    errorString = "[ * ] - %s"

    # Verbose
    print(infoString % "Getting information")

    # Start pagination index
    pagIndex = 1

    # Catch for keyboard interrupt
    try:

        # Paginate GitHubs response
        while True:

            # Verbose
            print(infoString % ("Page %d" % pagIndex), end='\r')

            # Create URL
            reposURL = "https://api.github.com/users/%s/repos?per_page=%d&page=%d" % (USER_NAME, PER_PAGE, pagIndex)

            # Get all repos
            repos = json.load(urllib.request.urlopen(reposURL))

            # Check if list is empty
            if repos:

                # Extract repo names
                cleanNames.extend([each["name"] for each in repos if each["name"] in myProjects["projects"]])

                # Increment pagination index
                pagIndex += 1

            # Break from loop if no more entries are returned
            else:
                print()
                break

    # If it was interrupted
    except KeyboardInterrupt:
        print()
        print(infoString % "Stopped paginating")

    # Exit if no projects were returned
    if not cleanNames:
        print(errorString % "Could not find any project")
        return

    # Cross-check repo names
    if reposChosen:
        crossedNames = [eachIn for eachIn in reposChosen if eachIn in cleanNames]

        # Check if all were found
        if len(crossedNames) != len(reposChosen):

            # Get all that weren't in the list and print them
            print("The following repos given were not found")
            print("\t", *[eachNot for eachNot in reposChosen if eachNot not in cleanNames])
            print("-" * 0b100000)
            print("Arguments given were")
            print("\t", *reposChosen)
            print("Possible repos are")
            print("\t", *cleanNames)

            # Return from error
            return

        # If all were found assign it to the variable
        else:
            cleanNames = crossedNames

    # Verbose
    infoString = "[ ! ] - %s"
    namesNumber = len(cleanNames)
    print( infoString % ("Found %d project%s..." % (namesNumber, 's' if namesNumber > 1 else '')) )
    print( infoString % "Acquiring information" )

    # Counter for projects acquired
    counterProjs = 0
    def printI(numberIn, maxNumber):
        maxSize = len(str(maxNumber))
        print( infoString % (
            ("Loading Projects... (%%%dd / %%d)" % maxSize) % (
                numberIn,
                maxNumber
            )
        ) , end='\r')

    # Import old project
    oldProjects = json.load(open(os.path.join(LOCATION, PROJECTS_FILE_NAME), 'r'))

    # Create object that is going to house all new projects
    newProjects = dict()

    # Try to add all the objects
    try:

        # Iterate and get commits
        for eachProject in sorted(cleanNames):

            # Get commit info
            projURL = "https://api.github.com/repos/%s/%s/branches" % (USER_NAME, eachProject)

            # Extract chosen branch and last commit hash
            chosenBranch = [each for each in json.load(urllib.request.urlopen(projURL)) if each["name"] == REPOS_BRANCH].pop()
            lastCommitHash = chosenBranch["commit"]["sha"]

            # Generate hash command
            hashCommand = "nix-prefetch-url --unpack https://github.com/%s/%s/archive/%s.tar.gz" % (USER_NAME, eachProject, lastCommitHash)

            # Run command and get output
            shaHash = subprocess.run(hashCommand.split(" "), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout.decode("utf-8").strip("\n")

            # Print
            counterProjs += 1
            printI(counterProjs, namesNumber)

            # Add item to object
            newProjects.update({
                eachProject: {
                    "commit": lastCommitHash,
                    "sha256": shaHash
                }
            })

    # If it was interrupted
    except KeyboardInterrupt:
        print(errorString % "Stopped adding projects")

    print()
    print( infoString % "All projects loaded" )
    print( infoString % "Generating list..." )

    # Create updated object
    updatedProjects = { key : oldProjects[key] for key in set(oldProjects) - set(newProjects) }

    # Create list of updated objects
    updatedProjectsNames = []

    # Compare both objects and update it
    for eachProj in newProjects:

        # Whether we should update the item
        updateIt = True

        # Check if they are identical
        if eachProj in oldProjects:
            matchCommit = newProjects[eachProj]["commit"] == oldProjects[eachProj]["commit"]
            matchSha256 = newProjects[eachProj]["sha256"] == oldProjects[eachProj]["sha256"]
            if matchCommit == matchSha256 == True:
                updateIt = False

        # Show what changed
        if updateIt:
            updatedProjectsNames.append(eachProj)

        # Update it
        updatedProjects.update({eachProj: newProjects[eachProj]})

    # Get length of biggest string
    listUpdatedProjects = list(updatedProjects)
    listUpdatedProjects.sort()
    bigLen = len(max(listUpdatedProjects, key=len))

    # Print headers
    formatString = " %%%ds   %%%ds   %%%ds" % (bigLen, COMMIT_LENGTH, HASH_LENGTH)
    print( formatString % ("Name", "Commit Hash", "Sha256") )
    print( formatString % ('-' * bigLen, '-' * COMMIT_LENGTH, '-' * HASH_LENGTH) )

    # Iterate updated items
    for eachUpdated in listUpdatedProjects:
        # Print the update ones
        if eachUpdated in updatedProjectsNames:
            if eachUpdated in oldProjects:
                if eachUpdated in newProjects:
                    print( '\033[33m', formatString % (eachUpdated, oldProjects[eachUpdated]["commit"], oldProjects[eachUpdated]["sha256"]), '\033[0m', sep='')
                else:
                    print( formatString % (eachUpdated, oldProjects[eachUpdated]["commit"], oldProjects[eachUpdated]["sha256"]) )
            else:
                print( formatString % (eachUpdated, "-", "-") )
            print( '\033[32m', formatString % (" ⮡ ", updatedProjects[eachUpdated]["commit"], updatedProjects[eachUpdated]["sha256"]), '\033[0m', sep='')
        else:
            print( formatString % (eachUpdated, updatedProjects[eachUpdated]["commit"], updatedProjects[eachUpdated]["sha256"]) )

    # Finally write it to file
    json.dump(updatedProjects, open(os.path.join(LOCATION, PROJECTS_FILE_NAME), 'w'), sort_keys=True, indent=4)


if __name__ == "__main__":
    main()

