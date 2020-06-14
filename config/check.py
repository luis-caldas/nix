#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Checks if the config files have valid attributes

import json
import copy
import os.path

from os import listdir

DEFAULT_FILE = "default.json"
CONFIG_FILE = "config.json"
SPACINGS = {
    "info": 4,
    "item": 8
}

def neoprint(string_in, type=2):
    visual = "%s " % ["✗", "!", "✓"][type]
    print "%s %s %s" % (SPACINGS["info"] * " ", visual, string_in)

def list_em_items(data_in):
    if isinstance(data_in, (set, list, tuple)):
        return [(index, value) for index, value in enumerate(data_in)]
    elif isinstance(data_in, dict):
        return data_in.items()

def get_its_item(structure, object_in):
    neopointer = object_in
    for each_struct in structure:
        try:
            _ = neopointer[each_struct]
        except:
            return False
        else:
            neopointer = neopointer[each_struct]
    return True

def get_its_item_redundant(structure, object_original, object_now):
    neopointer = object_original
    for each_struct in structure:
        try:
            _ = neopointer[each_struct]
        except:
            return True
        else:
            neopointer = neopointer[each_struct]

    if neopointer == object_now:
        return False

    return True

def object_compare(object_master, object_sub, previous_path=None, check_value=False):
    # Check if we have a previous path
    if not isinstance(previous_path, list):
        safe_previous_path = list()
    else:
        safe_previous_path = previous_path
    # List that will have all the paths missing
    root_list = list()
    # Iterate imediate objects
    for key, value in list_em_items(object_sub):
        # Append the key we are now in to the temp path
        inside_path = copy.deepcopy(safe_previous_path)
        inside_path.append(key)
        # Check if the data is still iterable
        if isinstance(value, dict) and value:
            # Recurse the function again to search for mismatches
            found_miss = object_compare(object_master, value, inside_path, check_value)
            # If the recursive function found any missmathes add it to the root
            if found_miss is not None:
                root_list.extend(found_miss)
        else:
            # Should we check for irregularities or redundancy
            if check_value:
                # List items that are reduntant
                if not get_its_item_redundant(inside_path, object_master, value):
                    root_list.append(inside_path)
            else:
                # If the data is not iterable compare it to the master object
                if not get_its_item(inside_path, object_master):
                    # Add it to the root list to be returned
                    root_list.append(inside_path)
    # Return the root list if it is not empty else return the list
    if root_list:
        return root_list
    else:
        return None

def load_json(file_in_path):
    try:
        loaded_json = json.load(open(file_in_path))
    except:
        neoprint("Unable to load file %s" % file_in_path, 0)
        return None
    else:
        return loaded_json


def main():

    # some path fixing
    base_folder = os.path.dirname(os.path.realpath(__file__))

    # import the default config file
    default_file_path = os.path.join(base_folder, DEFAULT_FILE)
    default_config = load_json(default_file_path)
    if default_config is None:
        return None

    # Get the config folders
    list_configs = []
    for each_config in listdir(base_folder):
        file_path_json = os.path.join(base_folder, each_config, CONFIG_FILE)
        if os.path.isdir(os.path.join(
            base_folder,
            each_config
        )):
            loaded_config = load_json(file_path_json)
            if loaded_config is None:
                return None
            list_configs.append({
                "path": file_path_json,
                "data": loaded_config
            })

    # Save the mismatches and redundancies
    mismatches = list()
    redundant  = list()

    # Check the configuration for irregular items
    for each_config in list_configs:
        
        # Show which config we are parsing
        print("-> %s <-" % each_config["path"])

        # Mismatch check
        check = object_compare(default_config, each_config["data"])
        if check is None:
            neoprint("No mismatches")
	else:
            neoprint("Mismatch", 0)
            # Show each entry missing
            for each_entry in check:
                quoted_list = [
                    "\"%s\"" % miss_item
                    if "." in miss_item else miss_item
                    for miss_item in each_entry
                ]
                print("%s | %s" % (" " * SPACINGS["item"], ".".join(quoted_list)))

        # Redundancy check
        check_redundant = object_compare(default_config, each_config["data"], check_value=True)
        if check_redundant is None:
            neoprint("No redundancy")
        else:
            neoprint("Redundancy", 0)
            # Show each entry missing
            for each_entry in check_redundant:
                quoted_list = [
                    "\"%s\"" % miss_item
                    if "." in miss_item else miss_item
                    for miss_item in each_entry
                ]
                print("%s | %s" % (" " * SPACINGS["item"], ".".join(quoted_list)))

if __name__ == "__main__":
    main()

