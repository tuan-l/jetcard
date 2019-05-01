#!/bin/sh

set -e
password="nvidia"
# enable i2c permissions
echo $password | sudo -S usermod -aG i2c $USER

# install pip and some apt dependencies
echo $password | sudo -S apt-get update
echo $password | sudo -S apt install -y python3-pip python3-pil python3-smbus python3-matplotlib cmake
echo $password | sudo -S pip3 install -U --upgrade numpy

# install tensorflow
echo $password | sudo -S apt-get install -y libhdf5-serial-dev hdf5-tools
echo $password | sudo -S apt-get install -y zlib1g-dev zip libjpeg8-dev libhdf5-dev
echo $password | sudo -S pip3 install -U numpy grpcio absl-py py-cpuinfo psutil portpicker grpcio six mock requests gast h5py astor termcolor
echo $password | sudo -S pip3 install -U --pre --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v42 tensorflow-gpu

# install pytorch
wget https://nvidia.box.com/shared/static/veo87trfaawj5pfwuqvhl6mzc5b55fbj.whl -O torch-1.1.0a0+b457266-cp36-cp36m-linux_aarch64.whl
echo $password | sudo -S pip3 install -U numpy torch-1.1.0a0+b457266-cp36-cp36m-linux_aarch64.whl
echo $password | sudo -S pip3 install -U torchvision

# setup Jetson.GPIO
echo $password | sudo -S groupadd -f -r gpio
echo $password | sudo -S usermod -a -G gpio $USER
echo $password | sudo -S cp /opt/nvidia/jetson-gpio/etc/99-gpio.rules /etc/udev/rules.d/
echo $password | sudo -S udevadm control --reload-rules && sudo udevadm trigger

# install traitlets (master)
echo $password | sudo -S python3 -m pip install git+https://github.com/ipython/traitlets@master

# install jupyter lab
echo $password | sudo -S apt install -y nodejs npm
echo $password | sudo -S pip3 install -U jupyter jupyterlab
echo $password | sudo -S jupyter labextension install @jupyter-widgets/jupyterlab-manager
echo $password | sudo -S jupyter labextension install @jupyterlab/statusbar
jupyter lab --generate-config
jupyter notebook password

# install jetcard
echo $password | sudo -S python3 setup.py install

# install jetcard stats service
python3 -m jetcard.create_stats_service
echo $password | sudo -S mv jetcard_stats.service /etc/systemd/system/jetcard_stats.service
echo $password | sudo -S systemctl enable jetcard_stats
echo $password | sudo -S systemctl start jetcard_stats

# install jetcard jupyter service
python3 -m jetcard.create_jupyter_service
echo $password | sudo -S mv jetcard_jupyter.service /etc/systemd/system/jetcard_jupyter.service
echo $password | sudo -S systemctl enable jetcard_jupyter
echo $password | sudo -S systemctl start jetcard_jupyter

# make swapfile
echo $password | sudo -S fallocate -l 4G /var/swapfile
echo $password | sudo -S chmod 600 /var/swapfile
echo $password | sudo -S mkswap /var/swapfile
echo $password | sudo -S swapon /var/swapfile
echo $password | sudo -S bash -c 'echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab'

# install TensorFlow models repository
git clone https://github.com/tensorflow/models
cd models/research
git checkout 5f4d34fc
wget -O protobuf.zip https://github.com/protocolbuffers/protobuf/releases/download/v3.7.1/protoc-3.7.1-linux-aarch_64.zip
# wget -O protobuf.zip https://github.com/protocolbuffers/protobuf/releases/download/v3.7.1/protoc-3.7.1-linux-x86_64.zip
unzip protobuf.zip
./bin/protoc object_detection/protos/*.proto --python_out=.
echo $password | sudo -S python3 setup.py install
cd slim
echo $password | sudo -S python3 setup.py install