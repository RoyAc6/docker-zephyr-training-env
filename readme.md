# AC6 Online PC – Docker Environment

This repository provides a Dockerized Ubuntu 22.04 desktop environment for VS Code, Workbench for Zephyr + Zazu Simulator extensions and Percepio View.

## Features

- XFCE graphical desktop
- Access via VNC (5901) or browser using noVNC (8080)
- VS Code, Zephyr Workbench and Zazu Simulator extensions preinstalled
- Tracealyzer for Zephyr included

## Build

docker build -t ac6-onlinepc .

Optional build arguments:

| ARG | Default |
|-----|---------|
| USERNAME | trainee |
| PASSWORD | Ac6@training |
| VNC_PORT | 5901 |
| NO_VNC_PORT | 8080 |
| RESOLUTION | 1920x1080 |

Example with overrides:

docker build \
  --build-arg USERNAME=john \
  --build-arg PASSWORD=secret \
  -t ac6-onlinepc .

## Run

### noVNC only

docker run -d -p 8080:8080 --name ac6 ac6-onlinepc

Open in browser:
http://localhost:8080

### VNC + noVNC

docker run -d \
  -p 8080:8080 \
  -p 5901:5901 \
  --name ac6 \
  ac6-onlinepc

The VNC password is the same as the container user's password.