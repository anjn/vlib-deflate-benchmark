Vitis Libraries Deflate benchmark
=================================

Setup
-----

```
git submodule update --init
```

Build xclbin
------------

```
export PLATFORM=xilinx_u200_xdma_201830_2
./build.sh
```

Run host
--------

```
export PLATFORM=xilinx_u200_xdma_201830_2
./run.sh INPUT_FILE
```
