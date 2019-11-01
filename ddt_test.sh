#!/usr/bin/env bash
set -ex

# prequisites
# sudo apt-get install libhdf5-mpich-dev

GIT_OPT="--depth 1"
BUILD=$HOME/ddt_test
ARM_FORGE="/home/philix/arm/forge"
export OPATH="$PATH"
export PATH="$BUILD/bin:$ARM_FORGE/bin:$PATH"

gcc -v
cmake --version
uname -a
ddt -v

mkdir -p $BUILD && cd $BUILD

[ ! -d $BUILD/mpich ]  && git clone https://github.com/pmodels/mpich -b v3.3.1 $BUILD/mpich
[ ! -d $BUILD/phare ]  && git clone https://github.com/dekken/PHARE -b mpi $GIT_OPT $BUILD/phare
[ ! -d $BUILD/samrai ] && git clone https://github.com/llnl/samrai -b master $GIT_OPT $BUILD/samrai

$BUILD/mpich && git submodule update --init
./autogen.sh --without-izem --without-ucx --without-libfabric
./configure --prefix=$BUILD --enable-g=all --disable-fast
make -j && make install && make clean

which mpicc

cd $BUILD/samrai && git submodule update --init
rm -rf build && mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$BUILD -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=$BUILD ..
make -j && make install && make clean

cd $BUILD/phare/subrojects
[ ! -d mkn.kul ]  && git clone https://github.com/mkn/mkn.kul -b master $GIT_OPT mkn.kul
cd $BUILD/phare && git submodule update --init
rm -rf build && mkdir -p build && cd build
cmake -DSAMRAI_ROOT=$BUILD/samrai -DCMAKE_INSTALL_PREFIX=$BUILD -DCMAKE_BUILD_TYPE=Debug ..
make -j

ddt -n 2 --debug --log=$PWD/DDT_PHARE.log $BUILD/phare/build/tests/amr/messengers/test-messenger
# break point $BUILD/phare/src/amr/data/field/file_data.h:231
#  step over a few times
