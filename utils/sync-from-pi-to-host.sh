#!/bin/bash
rsync -avz --delete pi@$IP:/lib $SYSROOT
rsync -avz --delete pi@$IP:/usr/include $SYSROOT/usr
rsync -avz --delete pi@$IP:/usr/lib $SYSROOT/usr
rsync -avz --delete pi@$IP:/opt/vc $SYSROOT/opt
