# webssh
![GitHub](https://img.shields.io/github/license/treehouses/webssh)
![GitHub](https://img.shields.io/docker/image-size/treehouses/webssh)
## Introduction
Web based ssh container based from treehouses alpine image. About webssh more can be view [here](https://pypi.org/project/webssh/).
## Installations:
```bash
git clone https://github.com/treehouses/webssh.git
cd webssh
docker build -t webssh .
```
## Usage:
- After build the docker image can run as a daemon service with default port 8888

   ``docker run -p 8888:8888 -d webssh``
- Open a browser and navigate to the ``serverip:8888``
