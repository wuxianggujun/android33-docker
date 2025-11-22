FROM debian:bookworm

ARG NODE_VERSION=20.11.0
ARG NDK_VERSION=r26d
ARG ANDROID_API=33
ARG TARGET_ARCH=arm64-v8a
ARG DEBIAN_MIRROR=http://mirrors.aliyun.com/debian
ARG DEBIAN_SECURITY_MIRROR=http://mirrors.aliyun.com/debian-security

ENV NODE_VERSION=${NODE_VERSION}
ENV NDK_VERSION=${NDK_VERSION}
ENV ANDROID_API=${ANDROID_API}
ENV TARGET_ARCH=${TARGET_ARCH}
ENV ANDROID_NDK_ROOT=/opt/android-ndk
ENV DEBIAN_FRONTEND=noninteractive

# Allow overriding mirrors for regions with slow access to the default Debian CDN
RUN if [ -f /etc/apt/sources.list ]; then \
        sed -i "s|http://deb.debian.org/debian|${DEBIAN_MIRROR}|g" /etc/apt/sources.list && \
        sed -i "s|http://security.debian.org/debian-security|${DEBIAN_SECURITY_MIRROR}|g" /etc/apt/sources.list; \
    fi && \
    if [ -d /etc/apt/sources.list.d ]; then \
        sed -i "s|http://deb.debian.org/debian|${DEBIAN_MIRROR}|g" /etc/apt/sources.list.d/debian.sources 2>/dev/null || true; \
    fi

# Build-only dependencies for compiling Node.js + libnode.so
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git python3 pkg-config curl ca-certificates unzip ccache && \
    rm -rf /var/lib/apt/lists/*

# Download and install Android NDK (with retry)
RUN for i in 1 2 3; do \
        curl -fsSL --retry 3 --retry-delay 5 \
            https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip \
            -o /tmp/ndk.zip && break || sleep 10; \
    done && \
    unzip -q /tmp/ndk.zip -d /opt && \
    mv /opt/android-ndk-${NDK_VERSION} ${ANDROID_NDK_ROOT} && \
    rm /tmp/ndk.zip

# Download and extract Node.js source
RUN curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.gz -o /tmp/node.tar.gz && \
    tar -xf /tmp/node.tar.gz -C /tmp && \
    rm /tmp/node.tar.gz

# Compile Android cpufeatures library
RUN cd ${ANDROID_NDK_ROOT}/sources/android/cpufeatures && \
    ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang \
        -c cpu-features.c -o cpu-features.o && \
    ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar rcs libcpufeatures.a cpu-features.o

# Configure Node.js for Android (optimized for size and build speed)
RUN cd /tmp/node-v${NODE_VERSION} && \
    export PATH="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}" && \
    export CC="ccache ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang" && \
    export CXX="ccache ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang++" && \
    export AR="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar" && \
    export RANLIB="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib" && \
    export CFLAGS="-Os -fdata-sections -ffunction-sections -I${ANDROID_NDK_ROOT}/sources/android/cpufeatures" && \
    export CXXFLAGS="-Os -fdata-sections -ffunction-sections -I${ANDROID_NDK_ROOT}/sources/android/cpufeatures" && \
    export LDFLAGS="-Wl,--gc-sections -L${ANDROID_NDK_ROOT}/sources/android/cpufeatures -lcpufeatures" && \
    export CC_host="ccache gcc" && \
    export CXX_host="ccache g++" && \
    export LINK_host=g++ && \
    export GYP_DEFINES="host_os=linux android_ndk_path=${ANDROID_NDK_ROOT}" && \
    ./configure \
        --shared \
        --dest-cpu=arm64 \
        --dest-os=android \
        --cross-compiling \
        --without-intl \
        --without-inspector \
        --without-npm \
        --without-corepack \
        --without-node-code-cache \
        --without-node-snapshot \
        --without-node-options \
        --without-report \
        --openssl-no-asm

# Fix host compiler flags
RUN cd /tmp/node-v${NODE_VERSION} && \
    find out -name "*.host.mk" -exec sed -i "s/-msign-return-address=all//g" {} \;

# Compile Node.js with Make
RUN cd /tmp/node-v${NODE_VERSION} && \
    export PATH="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}" && \
    export LDFLAGS="-Wl,--gc-sections -L${ANDROID_NDK_ROOT}/sources/android/cpufeatures -lcpufeatures" && \
    make -j$(nproc) && \
    echo "=== Build completed, checking output ===" && \
    find out -name "*.so*" -type f && \
    ls -la out/Release/

# Copy and strip libnode.so to output directory
RUN cd /tmp/node-v${NODE_VERSION} && \
    mkdir -p /output && \
    find out -name "libnode.so" -type f -exec cp {} /output/ \; && \
    echo "=== Before strip ===" && \
    ls -lh /output/ && \
    ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip /output/libnode.so && \
    echo "=== After strip ===" && \
    ls -lh /output/ && \
    test -f /output/libnode.so || (echo "ERROR: libnode.so not found!" && exit 1)

# Cleanup
RUN rm -rf /tmp/node-v${NODE_VERSION}

WORKDIR /workspace
CMD ["bash"]
