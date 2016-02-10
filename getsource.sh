source config.sh

sudo apt-get -y install git

cd $SRC_DIR
git clone https://github.com/fkanehiro/openhrp3.git
wget https://github.com/OctoMap/octomap/archive/v1.7.1.tar.gz
tar zxvf v1.7.1.tar.gz

if [ "$HAVE_ATOM_ACCESS" -eq 1 ]
then
    git clone ssh://atom.a01.aist.go.jp/git/HRP2
    git clone ssh://atom.a01.aist.go.jp/git/HRP2KAI.git
    git clone ssh://atom.a01.aist.go.jp/git/hrpsys-private
fi

git clone https://github.com/jrl-umi3218/hrp2-drc.git HRP2DRC
git clone https://github.com/fkanehiro/hrpsys-base.git
git clone https://github.com/jrl-umi3218/hmc2.git
git clone https://github.com/jrl-umi3218/hrpsys-humanoid.git
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
GIT_SSL_NO_VERIFY=1 git clone https://choreonoid.org/git/choreonoid.git
cd choreonoid/ext
git clone https://github.com/jrl-umi3218/hrpcnoid.git
cd ../..
fi
