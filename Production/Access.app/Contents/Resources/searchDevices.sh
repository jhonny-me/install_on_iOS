#!/bin/sh

#  searchDevices.sh
#  Access
#
#  Created by Johnny Gu on 19/03/2017.
#  Copyright © 2017 Johnny Gu. All rights reserved.

uuids=( $(mobiledevice list_devices) )
echo $uuids
