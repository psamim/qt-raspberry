# -*- mode: sh; -*-
#!/bin/bash
cd $QT_SOURCE
./configure -release \
            -opengl es2 \
            -device linux-rasp-pi2-g++ \
            -device-option CROSS_COMPILE=$TOOLS_DIR/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf- \
            -sysroot $SYSROOT \
            -opensource -confirm-license \
            -make libs \
            -prefix $PREFIX_TARGET \
            -extprefix $PREFIX_HOST \
            -hostprefix $PREFIX_HOST_BUILD_TOOLS \
            -v
