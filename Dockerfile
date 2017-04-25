FROM ubuntu:16.04
MAINTAINER alexcpn@gmail.com
# April 2017 
#  Docker file to build nvidia , cuda 8 , open-cv docker
# I am running a local ngixn server to server cuda and driver setp files via wget so that image size does not
# increase ; so run with the host name of the local webserver
# I have downloaded OpenCV and used CMAke GUI to confgire the CMake file for NVDIA Fermi arch for my card
# along with other settings for CUDA. For example I am not using or including Python. Basically this is to reduce
# compile time of the image and kepp image as small as possible
# Build like docker build --build-arg hostname=127.0.0.1 --network=host --tag nvidia-opencv:fermi .
# run like
# $ docker run  --device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm nvidia-opencv:fermi
# Output should be similar to below
#+-----------------------------------------------------------------------------+
#| NVIDIA-SMI 375.39                 Driver Version: 375.39                    |
#|-------------------------------+----------------------+----------------------+
#| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
#| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
#|===============================+======================+======================|
#|   0  GeForce GT 720M     Off  | 0000:01:00.0     N/A |                  N/A |
#| N/A   53C    P0    N/A /  N/A |    485MiB /  1985MiB |     N/A      Default |
#+-------------------------------+----------------------+----------------------+

ARG hostname    
# Install Updated NVIDIA Driver for GPU Card
RUN apt-get update && apt-get install -y build-essential && \
 apt-get --purge remove -y nvidia* && \
apt-get install module-init-tools -y  && \
 apt-get install -y wget && \
 rm -rf /var/lib/apt/lists/* && \
  wget    $hostname:8080/NVIDIA-Linux-x86_64-375.39.run && \
  chmod +x NVIDIA-Linux-x86_64*.run && \
  ./NVIDIA-Linux-x86_64*.run -s -N --no-kernel-module  && \
  rm -rf /temp/*  && \
  rm -rf NVIDIA-Linux-x86_64*.run 
# Install CUDA
RUN wget $hostname:8080/cuda_8.0.61_375.26_linux.run && \
  chmod +x cuda_*_linux.run && \
   ./cuda_*_linux.run --silent --toolkit && \
    rm -rf cuda_*_linux.run &&\
    rm -rf /temp/* && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64   
# Add CUDA library into your PATH
RUN touch /etc/ld.so.conf.d/cuda.conf 
# Get OpenCV Dependencies
RUN apt-get -y update && \
apt-get install -y cmake  pkg-config \
 zlib1g-dev ffmpeg libwebp-dev \
 libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev \ 
 libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
# These extra does not seem to be needed;  
# qt5-default  libtiff5-dev libopenexr-dev libgdal-dev   libdc1394-22-dev  libeigen3-dev 
# Get OpenCV and compile it
RUN wget http://localhost:8080/opencv.tar.gz && \   
 tar zxvf opencv.tar.gz && \
 cd opencv/build && \
 # This is the config for Fermi
 wget  $hostname:8080/CMakeCache.txt && \ 
 cmake . && \
 make install && \  
 cd / && \                         
 rm -rf opencv.tar.gz && \
 rm -rf opencv 
CMD nvidia-smi
