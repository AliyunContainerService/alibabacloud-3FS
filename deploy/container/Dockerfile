# syntax=docker/dockerfile:1.14

FROM ubuntu:22.04 AS base

ARG TARGETARCH
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache-$TARGETARCH \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib-$TARGETARCH \
    --mount=type=bind,src=erdma.acs,dst=/context/erdma.acs \
    cp /context/erdma.acs /etc/apt/keyrings/erdma.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/erdma.asc] http://mirrors.aliyun.com/erdma/apt/ubuntu jammy/erdma main" > /etc/apt/sources.list.d/erdma.list && \
    sed -i 's|http://.*\.ubuntu\.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update && \
    apt-get install -y \
        libaio1 \
        libatomic1 \
        libboost-atomic1.74.0 \
        libboost-context1.74.0 \
        libboost-filesystem1.74.0 \
        libboost-program-options1.74.0 \
        libboost-regex1.74.0 \
        libboost-system1.74.0 \
        libboost-thread1.74.0 \
        libdouble-conversion3 \
        libdwarf1 \
        libevent-2.1-7 \
        libgflags2.2 \
        libgoogle-glog0v5 \
        libgoogle-perftools4 \
        libibverbs1 \
        libsnappy1v5

FROM ubuntu:22.04 AS strip
ARG TARGETARCH
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache-$TARGETARCH \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib-$TARGETARCH \
    apt-get update && apt-get install -y binutils file

FROM scratch AS fdb-clients
ADD --link --checksum=sha256:c8ffc7604795719a11c615236c49cc8ac277fddd28caaa5fe670b11e6a54dc2f \
    https://github.com/apple/foundationdb/releases/download/7.1.61/foundationdb-clients_7.1.61-1_amd64.deb /fdb-clients.deb

FROM ubuntu:22.04 AS fdb-install
RUN --mount=type=bind,from=fdb-clients,dst=/fdb \
    dpkg -i /fdb/fdb-clients.deb

FROM base AS meta-base
COPY --link --from=fdb-install /usr/lib/libfdb_c.so /usr/lib/libfdb_c.so

FROM strip AS storage-strip
RUN --mount=type=bind,from=bin,dst=/build/bin --mount=type=bind,src=strip.sh,dst=/strip.sh /strip.sh storage_main
FROM strip AS meta-strip
RUN --mount=type=bind,from=bin,dst=/build/bin --mount=type=bind,src=strip.sh,dst=/strip.sh /strip.sh meta_main
FROM strip AS mgmtd-strip
RUN --mount=type=bind,from=bin,dst=/build/bin --mount=type=bind,src=strip.sh,dst=/strip.sh /strip.sh mgmtd_main
FROM strip AS admin-cli-strip
RUN --mount=type=bind,from=bin,dst=/build/bin --mount=type=bind,src=strip.sh,dst=/strip.sh /strip.sh admin_cli
FROM strip AS fuse-strip
RUN --mount=type=bind,from=bin,dst=/build/bin --mount=type=bind,src=strip.sh,dst=/strip.sh /strip.sh hf3fs_fuse_main

FROM base AS storage
COPY --link /config /etc
COPY --link --from=storage-strip /out/storage_main /usr/local/bin/storage_main
ENTRYPOINT ["/usr/local/bin/storage_main", "--launcher_cfg", "/etc/launcher.toml", "--app-cfg", "/etc/app.toml"]
FROM storage AS storage-debug
COPY --link --from=storage-strip /out/.build-id /usr/lib/debug/.build-id

FROM meta-base AS meta
COPY --link /config /etc
COPY --link --from=meta-strip /out/meta_main /usr/local/bin/meta_main
ENTRYPOINT ["/usr/local/bin/meta_main", "--launcher_cfg", "/etc/launcher.toml", "--app-cfg", "/etc/app.toml"]
FROM meta AS meta-debug
COPY --link --from=meta-strip /out/.build-id /usr/lib/debug/.build-id

FROM meta-base AS mgmtd
COPY --link /mgmtd /etc
COPY --link --from=mgmtd-strip /out/mgmtd_main /usr/local/bin/mgmtd_main
ENTRYPOINT ["/usr/local/bin/mgmtd_main", "--launcher_cfg", "/etc/launcher.toml", "--app-cfg", "/etc/app.toml"]
FROM mgmtd AS mgmtd-debug
COPY --link --from=mgmtd-strip /out/.build-id /usr/lib/debug/.build-id

FROM meta-base AS admin-cli
COPY --link --from=admin-cli-strip /out/admin_cli /usr/local/bin/admin_cli
ENTRYPOINT ["/usr/local/bin/admin_cli"]
FROM admin-cli AS admin-cli-debug
COPY --link --from=admin-cli-strip /out/.build-id /usr/lib/debug/.build-id

FROM base AS fuse
ARG TARGETARCH
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache-$TARGETARCH \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib-$TARGETARCH \
    apt-get update && apt-get install libnuma1
COPY --link /fuse /etc
COPY --link --from=fuse-strip /out/hf3fs_fuse_main /usr/local/bin/hf3fs_fuse_main
ENTRYPOINT ["/usr/local/bin/hf3fs_fuse_main", "--launcher_cfg", "/etc/launcher.toml", "--app-cfg", "/etc/app.toml"]
FROM fuse AS fuse-debug
COPY --link --from=fuse-strip /out/.build-id /usr/lib/debug/.build-id


FROM meta-base AS init-base
ARG TARGETARCH
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache-$TARGETARCH \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib-$TARGETARCH \
    apt-get update && apt-get install -y python3 curl

FROM init-base AS init-install
ARG TARGETARCH
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache-$TARGETARCH \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib-$TARGETARCH \
    apt-get update && apt-get install -y python3-pip

RUN --mount=type=bind,from=data_placement,src=/requirements.txt,dst=/data_placement/requirements.txt \
    --mount=type=bind,src=pip.conf,dst=/root/.pip/pip.conf \
    mkdir -p /install && pip install --root /install -r /data_placement/requirements.txt

FROM init-base AS init
COPY --link --from=admin-cli-strip /out/admin_cli /usr/local/bin/admin_cli
COPY --link --from=init-install /install /
COPY --link --from=data_placement / /root/data_placement
COPY --link init.sh /usr/local/bin/init.sh
ENTRYPOINT ["/usr/local/bin/init.sh"]
