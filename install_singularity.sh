sudo apt-get update
sudo apt-get -y install build-essential curl git sudo man vim autoconf libtool
git clone https://github.com/singularityware/singularity.git
cd singularity
./autogen.sh
./configure --prefix=/usr/local
make
sudo make install
