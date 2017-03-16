#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import sys

build = sys.argv[1]
c = sys.stdin.read()
d = json.loads(c)
for i in d['app_versions']:
    if i['version'] == build:
        print i['build_url']