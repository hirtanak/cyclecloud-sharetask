#!/bin/bash
# Copyright (c) 2020 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

echo "starting 10.master.sh"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# disabling selinux
echo "disabling selinux"
setenforce 0
sed -i -e "s/^SELINUX=enforcing$/SELINUX=disabled/g" /etc/selinux/config

CUSER=$(grep "Added user" /opt/cycle/jetpack/logs/jetpackd.log | awk '{print $6}')
CUSER=${CUSER//\'/}
CUSER=${CUSER//\`/}
# After CycleCloud 7.9 and later 
if [[ -z $CUSER ]]; then
   CUSER=$(grep "Added user" /opt/cycle/jetpack/logs/initialize.log | awk '{print $6}' | head -1)
   CUSER=${CUSER//\`/}
fi
echo ${CUSER} > /mnt/exports/shared/CUSER
HOMEDIR=/shared/home/${CUSER}
CYCLECLOUD_SPEC_PATH=/mnt/cluster-init/LSDYNA/master

LSDYNA_VERSION=$(jetpack config LSDYNA_VERSION)
MPI_PLATFORM=$(jetpack config MPI)
case ${LSDYNA_VERSION} in
    "r9_2_124508" )
        MPI_PLATFORM=platformmpi
    ;;
    "r9_2_121234" )
        MPI_PLATFORM=intelmpi-413
    ;;
    * )
        MPI_PLATFORM=$(jetpack config MPI)
    ;;
esac
LSDYNA_PLATFORM="x64_redhat54_ifort131_sse2_${MPI_PLATFORM}"

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# License Port Setting
LICENSE=$(jetpack config LICENSE)
(echo "export LSTC_LICENSE_SERVER=${LICENSE}"; echo "export MPI_HASIC_UDAPL=ofa-v2-ib0"; echo "export LD_LIBRARY_PATH=/shared/home/${CUSER}/apps/${MPI_PLATFORM/mpi/_mpi/}/lib/linux_amd64/") > /etc/profile.d/lsdyna.sh
chmod a+x /etc/profile.d/lsdyna.sh

# Azure VMs that have ephemeral storage mounted at /mnt/exports.
if [ ! -d ${HOMEDIR}/apps ]; then
   sudo -u ${CUSER} ln -s /mnt/exports/apps ${HOMEDIR}/apps
   chown ${CUSER}:${CUSER} /mnt/exports/apps
fi
chown ${CUSER}:${CUSER} /mnt/exports/apps | exit 0
if [ ! -d ${HOMEDIR}/apps/${LSDYNA_VERSION} ]; then
   mkdir -p ${HOMEDIR}/apps/${LSDYNA_VERSION}
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/${LSDYNA_VERSION}
fi
chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/${LSDYNA_VERSION} | exit 0

# LS-DYNA settings
if [ ! -f ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.tar.gz ]; then
   jetpack download ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.tar.gz ${HOMEDIR}/apps/${LSDYNA_VERSION}/
fi
if [ ! -d ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM} ]; then
   tar zxfp ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.tar.gz -C ${HOMEDIR}/apps/${LSDYNA_VERSION}
fi
if [ ! -f ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_d_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.tar.gz ]; then
   jetpack download ls-dyna_mpp_d_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.tar.gz ${HOMEDIR}/apps/${LSDYNA_VERSION}/ | exit 0
fi
if [ ! -d ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_d_${LSDYNA_VERSION}_${LSDYNA_PLATFORM} ]; then
   tar zxfp ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_d_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.tar.gz -C ${HOMEDIR}/apps/${LSDYNA_VERSION}/ | exit 0
fi

case ${MPI_PLATFORM} in
   "platformmpi" )
   if [ ! -d ${HOMEDIR}/apps/${MPI_PLATFORM/mpi/_mpi} ]; then
      jetpack download ${MPI_PLATFORM/mpi/_mpi}.tar.gz ${HOMEDIR}/apps/
      tar zxf ${HOMEDIR}/apps/${MPI_PLATFORM/mpi/_mpi}.tar.gz -C ${HOMEDIR}/apps/
   fi
   ;;
   "intelmpi" )
   echo "skip download" 
   ;;
esac

# make the LS-DYNA install dir readable by all
chmod +x ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM} || chmod +x ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}
chmod +x ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.l2a || chmod +x ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.l2a

if [ ! -f ${HOMEDIR}/apps/lsdyna ]; then
   ln -s ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM} ${HOMEDIR}/apps/lsdnya
fi
if [ ! -f ${HOMEDIR}/apps/lsdyna.l2a ]; then
   ln -s ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_s_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.l2a ${HOMEDIR}/apps/lsdnya.l2a
fi
if [ ! -f ${HOMEDIR}/apps/lsdyna-d ]; then
   if [ -f ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_d_${LSDYNA_VERSION}_${LSDYNA_PLATFORM} ]; then
   ln -s ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_d_${LSDYNA_VERSION}_${LSDYNA_PLATFORM} ${HOMEDIR}/apps/lsdnya-d
   fi
fi
if [ ! -f ${HOMEDIR}/apps/lsdyna-d.l2a ]; then
   if [ -f ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_d_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.l2a ]; then
   ln -s ${HOMEDIR}/apps/${LSDYNA_VERSION}/ls-dyna_mpp_d_${LSDYNA_VERSION}_${LSDYNA_PLATFORM}.l2a ${HOMEDIR}/apps/lsdnya-d.l2a
   fi
fi

if [ ! -d ${HOMEDIR}/apps/neon.refined.rev01.k.gz ]; then
   jetpack download neon.refined.rev01.k.gz ${HOMEDIR}/apps/
   gunzip -d ${HOMEDIR}/apps/neon.refined.rev01.k.gz 
   mv ${HOMEDIR}/apps/neon.refined.rev01.k ${HOMEDIR}/apps/ | exit 0
fi
chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps

# package
yum install -y htop

# file settings
if [ ! -f ${HOMEDIR}/lsdynasetup.sh ]; then
   cp ${CYCLECLOUD_SPEC_PATH}/files/lsdynasetup.sh ${HOMEDIR}
fi
chmod a+rx ${HOMEDIR}/lsdynasetup.sh
chown ${CUSER}:${CUSER} ${HOMEDIR}/lsdynasetup.sh

if [ ! -f ${HOMEDIR}/lsdynarun.sh ]; then
   cp ${CYCLECLOUD_SPEC_PATH}/files/lsdynarun.sh ${HOMEDIR}
fi
chmod a+rx ${HOMEDIR}/lsdynarun.sh
chown ${CUSER}:${CUSER} ${HOMEDIR}/lsdynarun.sh

#clean up
popd
rm -rf $tmpdir


echo "end 10.master.sh"
