#!/usr/bin/bash
#Copyright (c) 2020 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

echo "starting 10.install_sharetask.sh"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

#INSTALLSTAR=$(jetpack config INSTALLSTAR)
#
#if [[ ${INSTALLSTAR} == false ]] || [[ ${INSTALLSTAR} == False ]]; then
#   exit 0
#fi

# adapt multi user environment
SCRIPTUSER=$(jetpack config SCRIPTUSER)
if [[ ${SCRIPTUSER} = "None" ]]; then
   CUSER=$(grep "Added user" /opt/cycle/jetpack/logs/jetpackd.log | awk '{print $6}')
   CUSER=${CUSER//\'/}
   CUSER=${CUSER//\`/}
   # After CycleCloud 7.9 and later 
   if [[ -z $CUSER ]]; then
      CUSER=$(grep "Added user" /opt/cycle/jetpack/logs/initialize.log | awk '{print $6}' | head -1)
      CUSER=${CUSER//\`/}
      echo ${CUSER} > /mnt/exports/shared/CUSER
   fi
else
   CUSER=${SCRIPTUSER}
fi
echo ${CUSER} > /mnt/exports/shared/CUSER
HOMEDIR=/shared/home/${CUSER}
CYCLECLOUD_SPEC_PATH=/mnt/cluster-init/Sharetask/master

# default parameters
SHARETASK_VERSION=1.1.1
SHARETASK_VERSION=$(jetpack config SHARETASK_VERSION)
# get file name
SHARETASK_FILENAME=$(jetpack config SHARETASK_FILENAME)
# get platform parameters
#PLATFORM=${SHARETASK_FILENAME:33:5}
PLATFORM0=$(echo $SHARETASK_FILENAME | awk -F'-' '{print $5}')
PLATFORM=${PLATFORM0%%.tar.gz}
# set parameters
#SHARETASK_VERSION=${SHARETASK_FILENAME:9:9}
#REVISION=${SHARETASK_FILENAME:19:2}
#STARCCMPLUS_PLATFORM=${SHARETASK_FILENAME:22:12}
#PRECISION=${SHARETASK_FILENAME:35:2}

# check verion and fail
case "${SHARETASK_FILENAME}" in
  "sharetask-server-installer-1.1.1-azure.tar.gz" ) 
      echo "continue as default" ;;
  * ) echo "copy file to verion"
      SHARETASK_VERSION=$($SHARETASK_FILENAME | awk -F'-' '{print $4}') ;;
esac      
case "${PLATFORM}" in
  "azure" ) echo "continue to install" ;;
  *       ) echo "end of install due to no-azure package"
            exit 0 ;;
esac

# resource ulimit setting
CMD1=$(grep memlock ${HOMEDIR}/.bashrc | head -2)
if [[ -n "${CMD1}" ]]; then
  (echo "ulimit -m unlimited"; echo "source /etc/profile.d/sharetask.sh") >> ${HOMEDIR}/.bashrc
fi

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# Azure VMs that have ephemeral storage mounted at /mnt/exports.
if [ ! -d ${HOMEDIR}/apps ]; then
   sudo -u ${CUSER} ln -s /mnt/exports/apps ${HOMEDIR}/apps
   chown ${CUSER}:${CUSER} /mnt/exports/apps
fi
chown ${CUSER}:${CUSER} /mnt/exports/apps | exit 0

# install packages
#yum install -y perl-Digiest-MD5.x86_64 redhat-lsb-core vtk vtk-devel # gcc gcc-gcc++
yum install -y php-gd.x86_64 libgd-devel

# License File Setting
LICENSE=$(jetpack config LICENSE)
if [[ ! ${LICENSE} = "None" ]]; then
  (echo "export LICENSE=${LICENSE}") > /etc/profile.d/sharetask.sh
  chmod +x /etc/profile.d/shreatask.sh
  chown ${CUSER}:${CUSER} /etc/profile.d/shareask.sh
fi

# Download package
mkdir -p /home/sharetask
if [[ ! -f home/sharetask/${SHARETASK_FILENAME} ]]; then
   jetpack download "${SHARETASK_FILENAME}" /home/sharetask/${SHARETASK_FILENAME}
   chown ${CUSER}:${CUSER} /home/sharetask/${SHARETASK_FILENAME}
fi
# tar package
if [[ ! -d home/shareatask/Installer ]]; then
   chown ${CUSER}:${CUSER} /home/sharetask/${SHARETASK_FILENAME}
   tar zxfp /home/sharetask/${SHARETASK_FILENAME} -C /home/sharetask
   chown -R ${CUSER}:${CUSER} /home/sharetask/Installer
fi
# build setting
#alias gcc=/opt/gcc-9.2.0/bin/gcc
#alias c++=/opt/gcc-9.2.0/bin/c++
# PATH settings
#export PATH=/opt/gcc-9.2.0/bin/:$PATH
# install package
if [[ ! -f /home/shareatask/sharetask_server/sharetaskd/sharetaskd ]]; then
   # for build fail in cpan
   cpan -F GD
   cd /home/sharetask/Installer && make clean
   sed -i -e '130 s/-q/-q -o/g' /home/sharetask/Installer/Makefile6.initd
   cd /home/sharetask/Installer && make install
   cd /home/sharetask/Installer && make install-agent
fi

# local file settings

# file settings
chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps
cp /opt/cycle/jetpack/logs/cluster-init/Sharetask/master/scripts/10.install_sharetask.sh.out ${HOMEDIR}/
chown ${CUSER}:${CUSER} ${HOMEDIR}/10.install_sharetask.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 10.install_sharetask.sh"
