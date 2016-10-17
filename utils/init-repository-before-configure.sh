# -*- mode: sh; -*-
#!/bin/bash
# GODLEN: (find dev packages of qt modules)
# http://askubuntu.com/questions/508503/whats-the-development-package-for-qt5-in-14-04
cd $QT_SOURCE
./init-repository --module=$MODULES -f
