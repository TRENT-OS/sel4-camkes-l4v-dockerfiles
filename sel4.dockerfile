# Dependencies for compiling seL4
ARG BASE_TOOLS=base_tools
FROM $BASE_TOOLS
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)

# Add debian testing as a mirror.
# Add an apt preferences file, which states that stable is preferable than testing when automatically
# picking packages.
RUN echo 'deb http://httpredir.debian.org/debian/ testing main' > /etc/apt/sources.list.d/testing.list \
    && echo 'Package: *' >> /etc/apt/preferences \
    && echo 'Pin: release a=stable' >> /etc/apt/preferences \
    && echo 'Pin-Priority: 900' >> /etc/apt/preferences \
    && echo '' >> /etc/apt/preferences \
    && echo 'Package: *' >> /etc/apt/preferences \
    && echo 'Pin: release a=testing' >> /etc/apt/preferences \
    && echo 'Pin-Priority: 800' >> /etc/apt/preferences 

# Add additional architectures for cross-compiled libraries.
# Install the tools required to compile seL4.
RUN dpkg --add-architecture armhf \
    && dpkg --add-architecture armel \
    && apt-get update -q \
    && apt-get install -y --no-install-recommends \
        # STABLE packages!
        build-essential \
        ccache \
        cpio \
        g++-6 \
        gcc-6-multilib \
        gcc-6-base \
        gcc-arm-none-eabi \
        g++-6-aarch64-linux-gnu \
        g++-6-arm-linux-gnueabi \
        g++-6-arm-linux-gnueabihf \
        gcc-6-aarch64-linux-gnu \
        gcc-6-arm-linux-gnueabi \
        gcc-6-arm-linux-gnueabihf \
        gcc-6 \
        libcc1-0 \
        libxml2-utils \
        libncurses-dev \
        ninja-build \
        realpath \
        # TESTING packages!
        cmake/testing \
        cmake-curses-gui/testing \
        curl/testing \
        libuv1/testing \
        qemu/testing \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Set default compiler to be gcc-6 using update-alternatives
RUN for compiler in gcc \
                    g++; \
    do \
        for file in $(dpkg-query -L ${compiler} | grep /usr/bin/); \
        do \
            name=$(basename ${file}); \
            echo "$name - $file"; \
            #update-alternatives --install "${file}" "${name}" "${file}-5" 60; \
            update-alternatives --install "${file}" "${name}" "${file}-6" 50; \
            update-alternatives --auto "${name}"; \
        done \
    done \
    && \
    for compiler in gcc-6-arm-linux-gnueabi \
                    cpp-6-arm-linux-gnueabi \
                    gcc-6-aarch64-linux-gnu \
                    cpp-6-aarch64-linux-gnu \
                    gcc-6-arm-linux-gnueabihf \
                    cpp-6-arm-linux-gnueabihf \
                    g++-6-aarch64-linux-gnu \
                    g++-6-arm-linux-gnueabi \
                    g++-6-arm-linux-gnueabihf; \
    do \
        echo ${compiler}; \
        for file in $(dpkg-query -L ${compiler} | grep /usr/bin/); \
        do \
            name=$(basename ${file} | sed 's/-6$//g'); \
            link=$(echo ${file} | sed 's/-6$//g'); \
            echo "$name - $file"; \
            update-alternatives --install "${link}" "${name}" "${file}" 60; \
            update-alternatives --auto "${name}"; \
        done \
    done


# Get seL4 python2/3 deps
RUN for p in "pip2" "pip3"; \
    do \
        ${p} install --no-cache-dir \
            sel4-deps; \
    done

# Get specific version of Astyle used in seL4
RUN cd /root \
    && wget https://sourceforge.net/projects/astyle/files/astyle/astyle%202.04/astyle_2.04_linux.tar.gz/download -O astyle_2.04_linux.tar.gz \
    && tar -xf astyle_2.04_linux.tar.gz \
    && rm astyle_2.04_linux.tar.gz \
    && cd astyle/build/gcc \
    && make \
    && cp bin/astyle /usr/bin/astyle \
    && rm -rf /root/astyle

