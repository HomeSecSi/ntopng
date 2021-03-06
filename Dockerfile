FROM ubuntu:20.04
MAINTAINER HomeSecSi <homesecsi@ctemplar.com>
ENV WORKDIR /ntop
WORKDIR ${WORKDIR}
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install -y \
  autoconf \
  autogen \
  automake \
  bison \
  build-essential \
  debhelper \
  dkms \
  dpkg-sig \
  flex \
  gcc \
  geoipupdate \
  golang-go \
  git \
  libxtables-dev \
  libcairo2-dev \
  libcap-dev \
  libcurl4-openssl-dev \
  libgeoip-dev \
  libhiredis-dev \
  libjson-c-dev \
  libmaxminddb0 \
  libmaxminddb-dev \
  libmysqlclient-dev \
  libncurses5-dev \
  libnetfilter-conntrack-dev \
  libnetfilter-queue-dev \
  libpango1.0-dev \
  libpcap-dev \
  libpng-dev \
  libreadline-dev \
  librrd-dev \
  libsqlite3-dev \
  libssl-dev \
  libtool \
  libtool-bin \
  libxml2-dev \
  libzmq5-dev \
  mmdb-bin \
  net-tools \
  pkg-config \
  subversion \
  redis-server \
  rrdtool \
  wget \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

RUN git clone --branch 3.4-stable https://github.com/ntop/nDPI.git nDPI && git clone --branch 4.2-stable https://github.com/ntop/ntopng.git ntopng && git clone https://github.com/HomeSecSi/netflow2ng netflow2ng
COPY Makefile . 
COPY run.sh .
RUN make -B -j8 && mv /ntop/netflow2ng/dist/netflow2ng-v0.0.2-8-g887b99b-linux-x86_64 /ntop/netflow2ng-v0.0.2-8-g887b99b-linux-x86_64 && rm -r /ntop/netflow2ng && chmod +x ntopng/ntopng && chmod +x run.sh
EXPOSE 3000/tcp
EXPOSE 2055/udp
RUN mkdir /ntop/ntopng.prod && mv ntopng/httpdocs /ntop/ntopng.prod/ && mv ntopng/ntopng /ntop/ntopng.prod/ && mv ntopng/third-party /ntop/ntopng.prod/ && mv ntopng/scripts /ntop/ntopng.prod/ && mv ntopng/doc /ntop/ntopng.prod/ && rm -r ntopng nDPI && mv ntopng.prod ntopng && mkdir -p /var/lib/ntopng && useradd ntopng && usermod -d /ntop ntopng && chown ntopng:ntopng /var/lib/ntopng && chown -R ntopng:ntopng /ntop /var/lib/redis /var/log/redis /etc/redis && sed -i -e 's/redis:redis/ntopng:ntopng/g' /etc/init.d/redis-server && sed -i -e 's/User=redis/User=ntopng/g' /usr/lib/systemd/system/redis-server.service && sed -i -e 's/Group=redis/Group=ntopng/g' /usr/lib/systemd/system/redis-server.service
ENTRYPOINT ${WORKDIR}"/run.sh"

