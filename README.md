Vitis Libraries Deflate benchmark
=================================

Setup
-----

```bash
git submodule update --init
```

Build xclbin
------------

```bash
export PLATFORM=xilinx_u200_xdma_201830_2
# or, for AWS platform
export PLATFORM=$AWS_PLATFORM

./build.sh
```

Run host
--------

```bash
export PLATFORM=xilinx_u200_xdma_201830_2
# or, for AWS platform
export PLATFORM=$AWS_PLATFORM

./run.sh INPUT_FILE
```
