# ProNA p4-container

p4-container offers a P4 environment including all necessary tools and lab material used for P4-based courses in the NetLab at Fulda University of Applied Sciences. 

## Running p4-container in interactive mode, providing a shell command to execute inside the container

You can run the container in interactive mode using the ```-c``` parameter:

```
docker pull prona/p4-container
docker run -it --rm --privileged prona/p4-container -c bash
```

Additional arguments for the command to be executed in the container can also be specified.

```
docker pull prona/p4-container
docker run -it --rm --privileged prona/p4-container -c "bash -c ls"
```

The ```--privileged``` option is necessary to run mininet in the container, as typically done for P4 labs and tutorials.

## Using persistent storage in the container

You can mount a local directory to be used as persistent storage in the container. See mountpoints in Docker documentation for additional information. Example:

```
docker run -it --rm --privileged --mount type=bind,source="$(pwd)"/my-local-directory,target=/home/p4/my-local-directory prona/p4-container -c "bash -c ls /home/p4/my-local-directory"
```

## Running p4-container in service mode, e.g., to be used as a host instance for learn-sdn-hub

You can also use p4-container as host instance for [learn-sdn-hub](https://github.com/prona-p4-learning-platform/learn-sdn-hub) backend. In this case, start p4-container using the ```-s``` parameter.

```
docker pull prona/p4-container
docker run -it -p 3022:22 -p 3005:3005 --rm --privileged prona/p4-container -s
```

The container automatically starts an SSH daemon that can be used to login using user p4 and password p4 as typically used for P4 tutorials and environments. Also, a language server proxy is started on port 3005, that can be used by the monaco editor deployed with [learn-sdn-hub](https://github.com/prona-p4-learning-platform/learn-sdn-hub).

The ```--privileged``` option is necessary to run mininet in the container, as typically done for P4 labs and tutorials.

## CAUTION when using p4-container in WSL on Windows

Be advised, that if you want to run this container using Docker on Windows (using WSL2), some features in mininet, openvswitch, p4environment etc. will not be available to to lack of support for sch_netem in WSL2.
