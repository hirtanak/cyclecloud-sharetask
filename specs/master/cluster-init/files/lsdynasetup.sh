#!/bin/sh

LSDYNA_VERSION=$(jetpack config LSDYNA.version)
exprot LSTC_LICENSE_SERVER=$(jetpack config LICENSE)
export PATH=$PATH:~/apps/
export MPI_HASIC_UDAPL=ofa-v2-ib0
