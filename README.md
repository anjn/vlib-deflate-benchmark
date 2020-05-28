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
# or, you can specify the number of cus
./run.sh INPUT_FILE -n 4
```

Result
------

MB/s = 10^6 bytes/second

* xilinx_aws-vu9p-f1_shell-v04261818_201920_2

| Num instances | Clock Freq. [MHz] | Throughput [MB/s] |
|---------------|-------------------|-------------------|
| 1             | 250               | 1350              |
| 4             | 213               | 4010              |

* xilinx_u200_xdma_201830_2 @ PCIe Gen3 x8

| Num instances | Clock Freq. [MHz] | Throughput [MB/s] |
|---------------|-------------------|-------------------|
| 1             | 287               | 1700              |
| 4             | 271               | 4400~5300         |
