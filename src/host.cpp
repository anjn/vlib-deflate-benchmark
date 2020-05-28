/*
 * (c) Copyright 2019 Xilinx, Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
//#include "zlib.hpp"
#include <chrono>
#include <fstream>
#include <iomanip>
#include <vector>
#include <memory>
#include "cmdlineparser.h"
#include "deflate.hpp"

auto clock_now() {
  return std::chrono::high_resolution_clock::now();
}

template<typename T>
auto duration_sec(const T& end, const T& start) {
  return std::chrono::duration<double>(end - start).count();
}

struct stopwatch {
  using clock_type = decltype(clock_now());
  const std::string name;
  clock_type start, end;
  double duration;
  stopwatch(const std::string& name_): name(name_), start(clock_now()), duration(0) {}
  ~stopwatch() {
    if (end == clock_type()) stop();
    std::cout << name << ": " << std::fixed << std::setprecision(3) << (duration * 1000) << " ms" << std::endl;
  }
  void stop() {
    end = clock_now();
    duration = duration_sec(end, start);
  }
};

uint64_t get_file_size(std::ifstream& file) {
    file.seekg(0, file.end);
    uint64_t file_size = file.tellg();
    file.seekg(0, file.beg);
    return file_size;
}

void compress_file(deflate::deflate_fpga& def, std::string& in_file_name)
{
  auto out_file_name = in_file_name + ".zlib";

  // Open input file
  std::cout << "Open: " << in_file_name << std::endl;
  std::ifstream in_file(in_file_name, std::ios::in | std::ios::binary);
  if (!in_file) {
    std::cout << "Unable to open file";
    exit(1);
  }

  // Check file size
  const auto in_size = get_file_size(in_file);
  std::cout << "Input size: " << in_size << " bytes" << std::endl;

  // Allocate buffers
  deflate::host_buffer<uint8_t> in;
  deflate::host_buffer<uint8_t> out;
  {
    stopwatch sw("Allocate memory");
    in.resize(in_size);
    out.resize(in_size*2);
  }

  // Read input file
  {
    stopwatch sw("Read from file");
    in_file.read((char*)in.data(), in_size);
  }

  // Compress
  uint64_t out_size = 0;
  {
    stopwatch sw("Compress");
    out_size = def.compress(in.data(), out.data(), in_size);
    sw.stop();
    //double throughput = in_size / sw.duration / (1<<20);
    double throughput = in_size / sw.duration / 1e6;
    std::cout << "Throughput: " << std::fixed << std::setprecision(3) << throughput << " MB/s" << std::endl;;
  }

  // Write output file
  {
    stopwatch sw("Write to file");
    std::ofstream out_file(out_file_name, std::ios::out | std::ios::binary);
    out_file.put(120);
    out_file.put(1);
    out_file.write((char*)out.data(), out_size);
    out_file.put(0);
    out_file.put(0);
    out_file.put(0);
    out_file.put(0);
    out_file.put(0);
  }
}

int main(int argc, char* argv[]) {
  sda::utils::CmdLineParser parser;
  parser.addSwitch("--compress", "-c", "Compress", "");
  parser.addSwitch("--single_xclbin", "-sx", "Single XCLBIN", "single");
  parser.parse(argc, argv);

  std::string compress_mod = parser.value("compress");
  std::string single_bin = parser.value("single_xclbin");

  auto def = std::make_unique<deflate::deflate_fpga>();
  {
    stopwatch sw("Load FPGA");
    def->init(single_bin);
  }

  compress_file(*def, compress_mod);

  {
    stopwatch sw("Unload FPGA");
    def = nullptr;
  }
}
