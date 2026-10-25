# Build context: a PPSSPP checkout with the ext and ffmpeg submodules initialised.
# Stage "compile" -> ppsspp-headless:local, stage "run" -> ppsspp-headless-run:local.
# Both have PPSSPPHeadless on the PATH; assets/ sits next to the binary in /opt/ppsspp.
FROM debian:trixie AS compile
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build pkg-config python3 git ca-certificates \
        libsdl3-dev libsdl3-ttf-dev libfontconfig-dev libgl1-mesa-dev libglu1-mesa-dev libegl-dev \
    && rm -rf /var/lib/apt/lists/*
COPY . /src
ARG JOBS=6
RUN cmake -S /src -B /out -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DHEADLESS=ON -DUSE_DISCORD=OFF -DUSE_MINIUPNPC=OFF \
    && cmake --build /out --target PPSSPPHeadless -j "$JOBS" \
    && mkdir -p /opt/ppsspp && cp /out/PPSSPPHeadless /opt/ppsspp/ \
    && cp -r /src/assets /opt/ppsspp/assets \
    && ln -s /opt/ppsspp/PPSSPPHeadless /usr/local/bin/PPSSPPHeadless
WORKDIR /work

FROM debian:trixie AS run
RUN apt-get update && apt-get install -y --no-install-recommends \
        libsdl3-0 libsdl3-ttf0 libfontconfig1 libgl1 libglu1-mesa libegl1 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=compile /opt/ppsspp /opt/ppsspp
RUN ln -s /opt/ppsspp/PPSSPPHeadless /usr/local/bin/PPSSPPHeadless
WORKDIR /work
