#!/usr/bin/env python

import json
import copy
import os.path

from os import listdir

DEFAULT_FILE = "default.json"
CONFIG_FILE = "config.json"


def object_delete(object_input, key_name):
    new_object = copy.deepcopy(object_input)
    for each_key, each_value in vars(new_object).items():
        if each_key == key_name:
            del each_key
        elif isinstance(each_value, (dict, set, list, tuple)):
            each_value = object_delete(each_value, key_name)
    return new_object

def load_json(file_in_path):

    try:
        return json.load(open(file_in_path))
    except:
        print "Unable to load file %s" % file_in_path
        return None


def main():
   
    # some path fixing
    base_folder = os.path.dirname(os.path.realpath(__file__))

    # import the default config file
    default_file_path = os.path.join(base_folder, DEFAULT_FILE)
    default_config = load_json(default_file_path)
    if default_config is None:
        return None

    print json.dumps(default_config, indent=4, sort_keys=True)


if __name__ == "__main__":
    main()
