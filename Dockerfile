FROM ubuntu:20.04
#used p4lang/p4app before, but contained switch does not support thrift currently, maybe take a look at 2.0.0 as soon as it is released

LABEL de.hs-fulda.netlab.name="prona/p4-container" \
      de.hs-fulda.netlab.description="P4 and SDN learning environment example host instance to run assignments" \
      de.hs-fulda.netlab.url="https://github.com/prona-p4-learning-platform/p4-container" \
      de.hs-fulda.netlab.vcs-url="https://github.com/prona-p4-learning-platform/p4-container" \
      de.hs-fulda.netlab.docker.cmd="docker run -it --privileged -p 3005:3005 -p 22:22 prona/p4-container -s"

# default lsp lb port
EXPOSE 3005/tcp
# default ssh port
EXPOSE 22/tcp

# basic install depedencies
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update
#DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends --fix-missing install \
  sudo \
  curl \
  git \
  ca-certificates \
  openssh-server

# add a user p4 with password p4 as used by common p4 tutorials
RUN sudo useradd -m -d /home/p4 -s /bin/bash p4
RUN echo "p4:p4" | chpasswd
RUN echo "p4 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
USER p4
WORKDIR /home/p4

# install packages needed for common assignments
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends --fix-missing install \
  tmux \
  iperf \
  iperf3 \
  net-tools \ 
  iputils-ping \
  iputils-tracepath \
  mtr \ 
  htop \
  tcpdump \
  tshark \
  wget \
  unzip \
  vim \
  joe \
  nano

# install openvswitch - needed to run mininet from the console without p4 etc.
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends --fix-missing install \
  openvswitch-switch

# install docker
#curl -fsSL https://get.docker.com -o get-docker.sh
#sudo sh get-docker.sh

#sudo usermod -aG docker $USER
#newgrp docker
#sudo systemctl enable docker.service
#sudo systemctl enable containerd.service

# install firecracker?

# install node, needed to run language server proxy
# alternative: use nvm?
RUN curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends --fix-missing install\
  nodejs

# fetch typical tutorials and our p4-boilerplate and p4environment, so they can be used directly in the container for our courses
RUN git clone https://github.com/jafingerhut/p4-guide
# install scripts provided in p4-guide contain nearly everything we need for typical P4 assignments used in our masters' courses (e.g., p4c, bmv2, pi, mininet, ...)
# currently recommended version: install-p4dev-v5.sh
RUN p4-guide/bin/install-p4dev-v5.sh

# install-p4dev-v5.sh offers fast installation, but is not supporting python2 anymore, to be able to use python2, install-p4dev-v2.sh can be executed instead, though it will run ~100 minutes

# cleanup afterwards, as we don't need sources etc. for the labs, (jafingerhut p4-guide build stuff occupies ~6 GB)
#p4-guide/bin/install-p4dev-v2.sh && sudo rm -rf PI behavioral-model p4c grpc protobuf mininet install-details p4setup.bash p4setup.csh


###############################################################################
#
# all changes above this point will possibly cost you some hours of build
# time, as running install-p4dev-v2.sh can take some time compiling the
# entire p4 toolchain (PI behavioral-model p4c grpc protobuf mininet)
#
###############################################################################

RUN git clone https://github.com/p4lang/tutorials

RUN git clone https://github.com/nsg-ethz/p4-learning
RUN git clone https://github.com/prona-p4-learning-platform/p4-utils
# prevent p4-utils from installing dependencies, as this will install an break p4runtime etc.
# cause tutorials etc./p4 toolchain from install-p4dev.sh not to work anymore

# fixes in p4utils, otherwise p4 tutorials will not work anymore (conflicting version of p4runtime etc.)

#sed -i 's/pip3 install -e \".\"/pip3 install --no-deps -e \".\"/g' p4-utils/install.sh
#also: comment out every dep in setup.py:
#
#    #install_requires=[
#    #...
#    #],

# manually install missing deps
RUN sudo pip3 install networkx
RUN cd p4-utils && sudo ./install.sh
## learning controller examples require bridge-utils
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends --fix-missing install \
  bridge-utils
WORKDIR /home/p4

# p4env currently still depends on python2

## currently support for p4environment is disabled, due to missing netem support in the base container image
## also: p4environment kills eth0@ifXYZ interface providing ip address of container during stop
##
#git clone https://gitlab.cs.hs-fulda.de/flow-routing/cnsm2020/p4environment
### CAUTION: p4environment can currently not be used with wsl2 under windows due to missing sch_netem module/support
### python modules would also be installed by p4environment on first use, psutil already installed for p4 tutorials
## should be "scapy>=2.4.3", but currently p4environment would still install 2.4.3 anyway
#sudo pip install networkx "scapy==2.4.3" psutil numpy matplotlib scikit-learn pyyaml nnpy thrift
## fix for current mixup of python2 and python3 in p4-guide install script and p4environment deps still using python2
## luckily bm_runtime and sswitch_runtime do not seem to even use python3 stuff
#ln -s /usr/local/lib/python3.6/site-packages/bm_runtime /home/p4/p4environment/bm_runtime && \
#  ln -s /usr/local/lib/python3.6/site-packages/sswitch_runtime /home/p4/p4environment/sswitch_runtime

RUN git clone https://github.com/prona-p4-learning-platform/p4-boilerplate
# make examples using p4 tutorials relative utils import work in boilerplate
RUN ln -s tutorials/utils utils

## fix for current mixup of python2 and python3 in p4-guide install script
#ln -s /usr/local/lib/python3.6/site-packages/bmpy_utils.py /home/p4/p4-boilerplate/Example3-LearningSwitch/bmpy_utils.py && \
#  ln -s /usr/local/lib/python3.6/site-packages/bm_runtime /home/p4/p4-boilerplate/Example3-LearningSwitch/bm_runtime && \
#  ln -s /usr/local/lib/python3.6/site-packages/sswitch_runtime /home/p4/p4-boilerplate/Example3-LearningSwitch/sswitch_runtime

# fetch language server proxy
RUN git clone https://github.com/wylieconlon/jsonrpc-ws-proxy
RUN cd jsonrpc-ws-proxy && npm install && npm run prepare

WORKDIR /home/p4
# fetch our p4 langugage server/vscode extension
#RUN git clone https://github.com/prona-p4-learning-platform/p4-vscode-extension.git
#RUN cd p4-vscode-extension && npm install && cd server && npm run build && cp -a src/antlr_autogenerated build/

WORKDIR /home/p4
# fetch python language server
RUN pip install python-language-server

# configure language server proxy
#cat << EOF >> jsonrpc-ws-proxy/servers.yml
#langservers:
#  p4:
#    - node
#    - /home/p4/p4-vscode-extension/server/build/server.js
#    - --stdio
#  python:
#    - pyls
#EOF

#COPY servers.yml jsonrpc-ws-proxy/servers.yml

RUN echo 'langservers:\n\
  p4:\n\
    - node\n\
    - /home/p4/p4-vscode-extension/server/build/server.js\n\
    - --stdio\n\
  python:\n\
    - pyls\n'\
>> jsonrpc-ws-proxy/servers.yml


# finishing touches
# cleanup
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -y clean

# copy start script example
# cat << EOF >> /home/p4/start-p4-container.sh

# ensure unix line breaks
#sudo chmod +x /home/p4/start-p4-container.sh

RUN sudo update-rc.d ssh enable
RUN sudo update-rc.d openvswitch-switch enable

#cat << EOF >> lsp.service
#[Unit]
#Description=LSP load balancer server
#After=network.target
#
#[Service]
#Type=simple
#Restart=always
#RestartSec=1
#KillMode=process
#User=p4
#WorkingDirectory=/home/p4/jsonrpc-ws-proxy
#ExecStart=node dist/server.js --port 3005 --languageServers servers.yml
#
#[Install]
#WantedBy=multi-user.target
#Alias=lsp-loadbalancer.service
#EOF

RUN echo '[Unit]\n\
Description=LSP load balancer server\n\
After=network.target\n\
\n\
[Service]\n\
Type=simple\n\
Restart=always\n\
RestartSec=1\n\
KillMode=process\n\
User=p4\n\
WorkingDirectory=/home/p4/jsonrpc-ws-proxy\n\
ExecStart=node dist/server.js --port 3005 --languageServers servers.yml\n\
\n\
[Install]\n\
WantedBy=multi-user.target\n\
Alias=lsp-loadbalancer.service\n'\
>> lsp.service

RUN sudo cp lsp.service /lib/systemd/system/
RUN sudo systemctl enable lsp

# copy start script example
COPY start-p4-container.sh /home/p4/start-p4-container.sh
# ensure unix line breaks
RUN sudo chown p4:p4 /home/p4/start-p4-container.sh
RUN sudo chmod 755 /home/p4/start-p4-container.sh

ENTRYPOINT ["/home/p4/start-p4-container.sh"]
