#!/bin/bash
# Define build arguments
BUILD_TYPE=Release
LLVM_VERSION=20.1.4

# Clone LLVM repository
git clone -b llvmorg-${LLVM_VERSION} --depth 1 https://github.com/llvm/llvm-project.git

# Build core components in Release mode
cmake -S llvm-project/llvm -B build-release -G Ninja \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DCMAKE_C_COMPILER=clang-15 \
    -DCMAKE_CXX_COMPILER=clang++-15 \
    -DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra;lldb;mlir" \
    -DLLVM_ENABLE_RUNTIMES="libc;libunwind;libcxxabi;libcxx;openmp;compiler-rt" \
    -DLLVM_INSTALL_UTILS=True && \
    cmake --build build-release --target install

# remove build folders
rm -rf build-release build-debug llvm-project

