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

| Num instances | Clock Freq. | Throughput |
|---------------|-------------|------------|
| 1             | 250MHz      | 1350MB/s   |
| 4             | 213MHz      | 4010MB/s   |

* xilinx_u200_xdma_201830_2

| Num instances | Clock Freq. | Throughput |
|---------------|-------------|------------|
| 1             | 287MHz      | 1700MB/s   |
| 4             | 271MHz      | 4600~5200MB/s  |




