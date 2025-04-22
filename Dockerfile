FROM ubuntu:22.04 AS build

# Install build dependencies
RUN apt-get update -qq && apt-get -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  git-core \
  libass-dev \
  libfreetype6-dev \
  libgnutls28-dev \
  libmp3lame-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  meson \
  ninja-build \
  pkg-config \
  texinfo \
  wget \
  yasm \
  zlib1g-dev \
  libunistring-dev \
  libaom-dev \
  libdav1d-dev \
  nasm \
  libx264-dev \
  libx265-dev \
  libnuma-dev \
  libvpx-dev \
  libfdk-aac-dev \
  libopus-dev \
  libsvtav1enc-dev

# Build libdatachannel
RUN git clone --recursive https://github.com/paullouisageneau/libdatachannel.git \
  && cd libdatachannel \
  && cmake -B build -DUSE_GNUTLS=1 -DUSE_NICE=0 -DCMAKE_BUILD_TYPE=Release \
  && cmake --build build -- -j$(nproc) \
  && cmake --install build

# Build ffmpeg with libdatachannel
COPY . ffmpeg_sources/
RUN cd ffmpeg_sources && ./configure \
    --pkg-config-flags="--static" \
    --extra-libs="-lpthread -lm" \
    --ld="g++" \
    --enable-gpl \
    --enable-gnutls \
    --enable-libaom \
    --enable-libass \
    --enable-libdav1d \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libsvtav1 \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265 \
    --enable-nonfree \
    --enable-libdatachannel \
  && make -j$(nproc) \
  && make install

FROM ubuntu:22.04
# Install runtime dependencies
RUN apt-get update -qq && apt-get -y install \
  libass9 \
  libfreetype6 \
  libgnutls30 \
  libmp3lame0 \
  libsdl2-2.0-0 \
  libva2 \
  libva-drm2 \
  libva-x11-2 \
  libvdpau1 \
  libvorbis0a \
  libxcb1 \
  libxcb-shm0 \
  libxcb-xfixes0 \
  libxcb-shape0 \
  libxv1 \
  libsndio7.0 \
  zlib1g \
  libunistring2 \
  libaom3 \
  libdav1d5 \
  libx264-163 \
  libx265-199 \
  libnuma1 \
  libvpx7 \
  libfdk-aac2 \
  libopus0 \
  libsvtav1enc0 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local /usr/local
RUN ldconfig

ENTRYPOINT ["ffmpeg"]