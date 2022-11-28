FROM ubuntu:20.04
# used p4lang/p4app before, but contained switch does not support thrift currently, maybe take a look at 2.0.0 as soon as it is released

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

# install node, needed to run language server proxy
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends --fix-missing install\
  nodejs

# fetch typical tutorials and our p4-boilerplate and p4environment, so they can be used directly in the container for our courses
RUN git clone https://github.com/jafingerhut/p4-guide
# install scripts provided in p4-guide contain nearly everything we need for typical P4 assignments used in our masters' courses (e.g., p4c, bmv2, pi, mininet, ...)
# currently recommended version: install-p4dev-v5.sh
# see also: https://github.com/jafingerhut/p4-guide/blob/master/bin/README-install-troubleshooting.md
RUN p4-guide/bin/install-p4dev-v5.sh
# install-p4dev-v5.sh offers fast installation, but is not supporting python2 anymore, to be able to use python2, install-p4dev-v2.sh can be executed instead, though it will run ~100 minutes

# cleanup afterwards, as we don't need sources etc. for the labs, (jafingerhut p4-guide build stuff occupies ~6 GB)
# RUN p4-guide/bin/install-p4dev-v2.sh && sudo rm -rf PI behavioral-model p4c grpc protobuf mininet install-details p4setup.bash p4setup.csh

###############################################################################
#
# all changes above this point will possibly cost you some hours of build
# time, as running install-p4dev-v2.sh can take some time compiling the
# entire p4 toolchain (PI behavioral-model p4c grpc protobuf mininet)
#
###############################################################################

RUN git clone https://github.com/p4lang/tutorials
RUN git clone https://github.com/nsg-ethz/p4-learning
# commented out dependencies in p4-utils fork, otherwise p4 tutorials will not work anymore (conflicting version of p4runtime etc.)
RUN git clone https://github.com/prona-p4-learning-platform/p4-utils
# manually install missing dependencies
RUN sudo pip3 install networkx
RUN cd p4-utils && sudo ./install.sh
# learning controller examples require bridge-utils
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends --fix-missing install \
  bridge-utils

# p4env currently still depends on python2
# currently support for p4environment is disabled, due to missing netem support in the base container image
# also: p4environment kills eth0@ifXYZ interface providing ip address of container during stop

RUN git clone https://github.com/prona-p4-learning-platform/p4-boilerplate
# make examples using p4 tutorials relative utils import work in boilerplate
RUN ln -s tutorials/utils utils

# install ryu
RUN git clone https://github.com/faucetsdn/ryu.git && cd ryu && sudo pip3 install .

# fetch language server proxy
RUN git clone https://github.com/wylieconlon/jsonrpc-ws-proxy
RUN cd jsonrpc-ws-proxy && npm install && npm run prepare

# fetch our p4 langugage server/vscode extension
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends --fix-missing install \
  g++
RUN sudo npm install -g node-gyp
RUN git clone --recurse-submodules https://github.com/prona-p4-learning-platform/p4-ls.git
RUN cd p4-ls && npm install && npm run compile:ls

# fetch our legacy p4 langugage server/vscode extension
# use p4-ls for now, as legacy extension depends on removed vscode engine version, leading to a 404 Cannot GET /api/releases/stable
#RUN git clone https://github.com/prona-p4-learning-platform/p4-vscode-extension.git
#RUN cd p4-vscode-extension && npm install && cd server && npm run build && cp -a src/antlr_autogenerated build/

# fetch python language server
# use python-lsp-server for now, as python-language-server seams to be not maintained anymore
#RUN sudo pip install python-language-server
RUN sudo pip install python-lsp-server[all]

# configure language server proxy
COPY servers.yml jsonrpc-ws-proxy/servers.yml

RUN sudo update-rc.d ssh enable
RUN sudo update-rc.d openvswitch-switch enable

# configure lsp service
COPY lsp.service /lib/systemd/system/
RUN sudo systemctl enable lsp

# cleanup
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -y clean

# copy start script example
COPY start-p4-container.sh /home/p4/start-p4-container.sh
RUN sudo chown p4:p4 /home/p4/start-p4-container.sh
RUN sudo chmod 755 /home/p4/start-p4-container.sh

ENTRYPOINT ["/home/p4/start-p4-container.sh"]
