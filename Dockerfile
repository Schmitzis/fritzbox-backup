FROM    debian:bullseye-slim

ENV     TERM=xterm-256color \
        DEBIAN_FRONTEND=noninteractive \
        TZ='Europe/Berlin' \
        APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

RUN     chsh -s /bin/bash \
&&      ln -sf /bin/bash /bin/sh \
&&      echo 'deb http://deb.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/backports.list \
&&      echo 'Package: *\nPin: release a=bullseye-backports\nPin-Priority: 1001' | tee -a /etc/apt/preferences.d/10-backports-pin \
&&      apt-get update \
&&      apt-get -y upgrade

# install basic required utils
RUN     BUILD_DEPS=" \
            bash \
            curl \
            openssl \
            s3cmd \
        " \
&&      apt-get update \
&&      apt-get -y install --no-install-recommends $BUILD_DEPS \
            ca-certificates \
            procps \

# clean up cache
&&      apt-get clean \
&&      rm -rf \
            /var/lib/apt/lists/* \
            /tmp/* \
            /var/tmp/* \
            /home/.cache


VOLUME          [ "/data" ]
ENTRYPOINT      [ "/entrypoint.sh" ]
ADD             /entrypoint.sh  /
ADD             /fritzbox-backup-export.sh  /
ADD             /minio-put.sh /
RUN             chmod -R +x \
                        /entrypoint.sh \
                        /fritzbox-backup-export.sh \
                        /minio-put.sh
