#
# Copyright 2019 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
############################## Help Section ##############################
.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86>"
	$(ECHO) "      Command to generate the design for specified Target and Shell."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
	$(ECHO) "  make sd_card TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86>"
	$(ECHO) "      Command to prepare sd_card files."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make run TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86>"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make build TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86>"
	$(ECHO) "      Command to build xclbin application."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make host DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86>"
	$(ECHO) "      Command to build host application."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  NOTE: For SoC shells, ENV variable SYSROOT needs to be set."
	$(ECHO) ""

############################## Setting up Project Variables ##############################
MK_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
XF_PROJ_ROOT := $(dir $(MK_PATH))/external/Vitis_Libraries/data_compression
CUR_DIR := $(patsubst %/,%,$(dir $(MK_PATH)))
XFLIB_DIR = $(XF_PROJ_ROOT)

TARGET ?= sw_emu
HOST_ARCH := x86
SYSROOT := ${SYSROOT}
DEVICE ?= xilinx_u200_xdma_201830_2

ifeq ($(findstring zc, $(DEVICE)), zc)
$(error This design is not supported for $(DEVICE))
endif
ifeq ($(findstring vck, $(DEVICE)), vck)
$(error This design is not supported for $(DEVICE))
endif

ifneq ($(findstring u200, $(DEVICE)), u200)
ifneq ($(findstring u250, $(DEVICE)), u250)
ifneq ($(findstring u280, $(DEVICE)), u280)
$(warning [WARNING]: This design has not been tested for $(DEVICE). It may or may not work.)
endif
endif
endif

include ./utils.mk

XDEVICE := $(call device2xsa, $(DEVICE))
TEMP_DIR := _x_temp.$(TARGET).$(XDEVICE)
TEMP_REPORT_DIR := $(CUR_DIR)/reports/_x.$(TARGET).$(XDEVICE)
BUILD_DIR := build_dir.$(TARGET).$(XDEVICE)
BUILD_REPORT_DIR := $(CUR_DIR)/reports/_build.$(TARGET).$(XDEVICE)
EMCONFIG_DIR := $(BUILD_DIR)

# Setting tools
VPP := v++

include config.mk

############################## Setting up Host Variables ##############################
#Include Required Host Source Files
HOST_SRCS += ./src/host.cpp
HOST_SRCS += $(XFLIB_DIR)/common/libs/xcl2/xcl2.cpp
HOST_SRCS += $(XFLIB_DIR)/common/libs/cmdparser/cmdlineparser.cpp
HOST_SRCS += $(XFLIB_DIR)/common/libs/logger/logger.cpp
HOST_SRCS += $(XFLIB_DIR)/common/thirdParty/xxhash/xxhash.c

HOST_HDRS += ./src/deflate.hpp

CXXFLAGS += -DPARALLEL_BLOCK=8

CXXFLAGS += -I$(XFLIB_DIR)/L1/include/hw
CXXFLAGS += -I$(XFLIB_DIR)/L3/include

CXXFLAGS += -I$(XFLIB_DIR)/common/libs/xcl2
CXXFLAGS += -I$(XFLIB_DIR)/common/libs/cmdparser
CXXFLAGS += -I$(XFLIB_DIR)/common/libs/logger
CXXFLAGS += -I$(XFLIB_DIR)/L2/tests/src/
CXXFLAGS += -I$(XFLIB_DIR)/common/thirdParty/xxhash

# Host compiler global settings
CXXFLAGS += -I$(XILINX_XRT)/include -I$(XILINX_VIVADO)/include -std=c++14 -Wall -Wno-unknown-pragmas -Wno-unused-label 
CXXFLAGS += -O3
#CXXFLAGS += -O0 -g -fno-inline
LDFLAGS += -L$(XILINX_XRT)/lib -lOpenCL -lpthread -lrt -Wno-unused-label -Wno-narrowing -DVERBOSE 
CXXFLAGS += -fmessage-length=0 
CXXFLAGS +=-I$(CUR_DIR)/src/ 


EXE_NAME := deflate
EXE_FILE := $(BUILD_DIR)/$(EXE_NAME)
HOST_ARGS := -sx $(BUILD_DIR)/compress_decompress.xclbin -v $(CUR_DIR)/sample.txt

ifneq ($(HOST_ARCH), x86)
	LDFLAGS += --sysroot=$(SYSROOT)
endif

############################## Setting up Kernel Variables ##############################
NUM_THREADS ?= 16

# Kernel compiler global settings
VPP_FLAGS += -t $(TARGET) --platform $(XPLATFORM) --save-temps
#VPP_FLAGS += --kernel_frequency 500
LDCLFLAGS += --optimize 3 --jobs $(NUM_THREADS)
VPP_FLAGS +=-I$(XFLIB_DIR)/L1/include/hw
VPP_FLAGS +=-I$(XFLIB_DIR)/L2/include
VPP_FLAGS +=-I$(XFLIB_DIR)/L2/src


VPP_FLAGS += --config $(CUR_DIR)/advanced.ini 
VPP_FLAGS += -DPARALLEL_BLOCK=8 -DHIGH_FMAX_II=2 -DMULTIPLE_BYTES=4 

# Kernel linker flags
LDCLFLAGS_compress_decompress += --config $(CUR_DIR)/opts_u280.ini
LDCLFLAGS_compress_decompress += --advanced.param compiler.userPostSysLinkOverlayTcl=$(shell readlink -f vivado_param.tcl)
LDCLFLAGS_compress_decompress += --xp "vivado_prop:run.impl_1.{STEPS.ROUTE_DESIGN.ARGS.MORE OPTIONS}={-ultrathreads}"

############################## Declaring Binary Containers ##############################
BINARY_CONTAINERS += $(BUILD_DIR)/compress_decompress.xclbin
BINARY_CONTAINER_compress_decompress_OBJS += $(TEMP_DIR)/xilLz77Compress.xo
BINARY_CONTAINER_compress_decompress_OBJS += $(TEMP_DIR)/xilHuffmanKernel.xo
#BINARY_CONTAINER_compress_decompress_OBJS += $(TEMP_DIR)/xilZlibDmReader.xo
#BINARY_CONTAINER_compress_decompress_OBJS += $(TEMP_DIR)/xilZlibDmWriter.xo
#BINARY_CONTAINER_compress_decompress_OBJS += $(TEMP_DIR)/xilDecompressStream.xo

############################## Setting Targets ##############################
CP = cp -rf

.PHONY: all clean cleanall docs emconfig
all: check_vpp check_platform | $(EXE_FILE) $(BINARY_CONTAINERS) emconfig 

.PHONY: host
host: $(EXE_FILE) | check_xrt

.PHONY: xclbin
xclbin: check_vpp | $(BINARY_CONTAINERS)

.PHONY: build
build: xclbin

############################## Setting Rules for Binary Containers (Building Kernels) ##############################
$(TEMP_DIR)/xilLz77Compress.xo: $(XFLIB_DIR)/L2/src/zlib_lz77_compress_mm.cpp
	$(ECHO) "Compiling Kernel: xilLz77Compress"
	mkdir -p $(TEMP_DIR)
	$(VPP) $(xilLz77Compress_VPP_FLAGS) $(VPP_FLAGS) --temp_dir $(TEMP_DIR) --report_dir $(TEMP_REPORT_DIR) -c -k xilLz77Compress -I'$(<D)' -o'$@' '$<'
$(TEMP_DIR)/xilHuffmanKernel.xo: $(XFLIB_DIR)/L2/src/zlib_huffman_enc_mm.cpp
	$(ECHO) "Compiling Kernel: xilHuffmanKernel"
	mkdir -p $(TEMP_DIR)
	$(VPP) $(xilHuffmanKernel_VPP_FLAGS) $(VPP_FLAGS) --temp_dir $(TEMP_DIR) --report_dir $(TEMP_REPORT_DIR) -c -k xilHuffmanKernel -I'$(<D)' -o'$@' '$<'
$(TEMP_DIR)/xilZlibDmReader.xo: $(XFLIB_DIR)/L2/tests/src/zlib_dm_multibyte_rd.cpp
	$(ECHO) "Compiling Kernel: xilZlibDmReader"
	mkdir -p $(TEMP_DIR)
	$(VPP) $(xilZlibDmReader_VPP_FLAGS) $(VPP_FLAGS) --temp_dir $(TEMP_DIR) --report_dir $(TEMP_REPORT_DIR) -c -k xilZlibDmReader -I'$(<D)' -o'$@' '$<'
$(TEMP_DIR)/xilZlibDmWriter.xo: $(XFLIB_DIR)/L2/tests/src/zlib_dm_multibyte_wr.cpp
	$(ECHO) "Compiling Kernel: xilZlibDmWriter"
	mkdir -p $(TEMP_DIR)
	$(VPP) $(xilZlibDmWriter_VPP_FLAGS) $(VPP_FLAGS) --temp_dir $(TEMP_DIR) --report_dir $(TEMP_REPORT_DIR) -c -k xilZlibDmWriter -I'$(<D)' -o'$@' '$<'
$(TEMP_DIR)/xilDecompressStream.xo: $(XFLIB_DIR)/L2/src/zlib_parallelbyte_decompress_stream.cpp
	$(ECHO) "Compiling Kernel: xilDecompressStream"
	mkdir -p $(TEMP_DIR)
	$(VPP) $(xilDecompressStream_VPP_FLAGS) $(VPP_FLAGS) --temp_dir $(TEMP_DIR) --report_dir $(TEMP_REPORT_DIR) -c -k xilDecompressStream -I'$(<D)' -o'$@' '$<'

$(BUILD_DIR)/compress_decompress.xclbin: $(BINARY_CONTAINER_compress_decompress_OBJS)
	mkdir -p $(BUILD_DIR)
	$(VPP) $(VPP_FLAGS) --temp_dir $(BUILD_DIR) --report_dir $(BUILD_REPORT_DIR)/compress_decompress -l $(LDCLFLAGS) $(LDCLFLAGS_compress_decompress) -o'$@' $(+)

############################## Setting Rules for Host (Building Host Executable) ##############################
$(EXE_FILE): $(HOST_SRCS) $(HOST_HDRS) | check_xrt
	mkdir -p $(BUILD_DIR)
	$(CXX) -o $@ $(HOST_SRCS) $(CXXFLAGS) $(LDFLAGS)

emconfig:$(EMCONFIG_DIR)/emconfig.json
$(EMCONFIG_DIR)/emconfig.json:
	emconfigutil --platform $(XPLATFORM) --od $(EMCONFIG_DIR)

############################## Setting Essential Checks and Running Rules ##############################
run: all
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) $(EXE_FILE) $(HOST_ARGS)
	XCL_EMULATION_MODE=$(TARGET) ./run.sh $(EXE_FILE) $(XFLIB_DIR) $(BUILD_DIR)/compress_decompress.xclbin
else
	$(EXE_FILE) $(HOST_ARGS)
	./run.sh $(EXE_FILE) $(XFLIB_DIR) $(BUILD_DIR)/compress_decompress.xclbin
endif

############################## Cleaning Rules ##############################
cleanh:
	-$(RMDIR) $(EXE_FILE) vitis_* TempConfig system_estimate.xtxt *.rpt .run/
	-$(RMDIR) src/*.ll _xocc_* .Xil dltmp* xmltmp* *.log *.jou *.wcfg *.wdb

cleank:
	-$(RMDIR) $(BUILD_DIR)/*.xclbin _vimage *xclbin.run_summary qemu-memory-_* emulation/ _vimage/ pl* start_simulation.sh *.xclbin
	-$(RMDIR) _x_temp.*/_x.* _x_temp.*/.Xil _x_temp.*/profile_summary.* 
	-$(RMDIR) _x_temp.*/dltmp* _x_temp.*/kernel_info.dat _x_temp.*/*.log 
	-$(RMDIR) _x_temp.* 

cleanall: cleanh cleank
	-$(RMDIR) $(BUILD_DIR)  build_dir.* emconfig.json *.html $(TEMP_DIR) $(CUR_DIR)/reports *.csv *.run_summary $(CUR_DIR)/*.raw
	-$(RMDIR) $(XFLIB_DIR)/common/data/*.xe2xd* $(XFLIB_DIR)/common/data/*.orig*
	-$(RMDIR) ./sample.txt.* ./sample_run.* ./test.list 

clean: cleanh
