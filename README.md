# Azure CycleCloud template for Sharetask

## Prerequisites

1. Prepaire for your Sharetask bilnary.
1. Install CycleCloud CLI

## How to install 

1. tar zxvf cyclecloud-Sharetask.tar.gz
1. cd cyclecloud-Sharetask
1. mv project.ini.sample project.ini
1. Uplaod "Files" attribute for your Sharetask binariy in "project.ini" file.
1. run "cyclecloud project upload azure-storage" for uploading template to CycleCloud
1. "cyclecloud import_template -f templates/pbs_extended_nfs_lsdyna.txt" for register this template to your CycleCloud

1. cyclecloud delete_template Sharetask

## How to run Sharetask

1. Create Execute Node manually
1. Check Node IP Address
1. Create hosts file for your nodes
1. qsub ~/lsdynarun.sh (sample as below)

<pre><code>
#!/bin/bash
#PBS -j oe
#PBS -l nodes=2:ppn=16

Sharetask_DIR="/shared/home/azureuser/apps"
MPI_ROOT="/shared/home/azureuser/apps/platform_mpi/bin"
INPUT="/shared/home/azureuser/apps/neon.refined.rev01.k"

${MPI_ROOT}/mpirun -np ${NP} ${Sharetask_DIR}/ls-dyna_mpp_s_R9_3_0_x64_redhat54_ifort131_sse2_platformmpi info 
</pre></code>

## Known Issues
1. This tempate support only single administrator. So you have to use same user between superuser(initial Azure CycleCloud User) and deployment user of this template

# Azure CycleCloud用テンプレート:Sharetask(NFS/PBSPro)

[Azure CycleCloud](https://docs.microsoft.com/en-us/azure/cyclecloud/) はMicrosoft Azure上で簡単にCAE/HPC/Deep Learning用のクラスタ環境を構築できるソリューションです。

![Azure CycleCloudの構築・テンプレート構成](https://raw.githubusercontent.com/hirtanak/osspbsdefault/master/AzureCycleCloud-OSSPBSDefault.png "Azure CycleCloudの構築・テンプレート構成")

Azure CyceCloudのインストールに関しては、[こちら](https://docs.microsoft.com/en-us/azure/cyclecloud/quickstart-install-cyclecloud) のドキュメントを参照してください。

Sharetask用のテンプレートになっています。
以下の構成、特徴を持っています。

1. OSS PBS ProジョブスケジューラをMasterノードにインストール
1. H16r, H16r_Promo, HC44rs, HB60rs, HB120rs_v2を想定したテンプレート、イメージ
	 - OpenLogic CentOS 7.6 HPC を利用 
1. Masterノードに512GB * 2 のNFSストレージサーバを搭載
	 - Executeノード（計算ノード）からNFSをマウント
1. MasterノードのIPアドレスを固定設定
	 - 一旦停止後、再度起動した場合にアクセスする先のIPアドレスが変更されない

![OSS PBS Default テンプレート構成](https://raw.githubusercontent.com/hirtanak/osspbsdefault/master/OSSPBSDefaultDiagram.png "OSS PBS Default テンプレート構成")

OSS PBS Defaultテンプレートインストール方法

前提条件: テンプレートを利用するためには、Azure CycleCloud CLIのインストールと設定が必要です。詳しくは、 [こちら](https://docs.microsoft.com/en-us/azure/cyclecloud/install-cyclecloud-cli) の文書からインストールと展開されたAzure CycleCloudサーバのFQDNの設定が必要です。

1. テンプレート本体をダウンロード
1. 展開、ディレクトリ移動
1. cyclecloudコマンドラインからテンプレートインストール 
   - tar zxvf cyclecloud-Sharetask<version>.tar.gz
   - cd cyclecloud-Sharetask<version>
   - cyclecloud project upload cyclecloud-storage # 以前は、cyclecloud project upload azure-storage
   - cyclecloud import_template -f templates/pbs_extended_nfs_sharetask.txt
1. 削除したい場合、 cyclecloud delete_template sharetask コマンドで削除可能

***
Copyright Hiroshi Tanaka, hirtanak@gmail.com, @hirtanak All rights reserved.
Use of this source code is governed by MIT license that can be found in the LICENSE file.
