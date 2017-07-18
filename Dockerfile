FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -y apt-transport-https

RUN echo "deb [trusted=yes] https://repo.iovisor.org/apt/xenial xenial-nightly main" | tee /etc/apt/sources.list.d/iovisor.list && \
    apt-get update && \
    apt-get install -y bcc-tools libbcc-examples

RUN apt-get install -y bcc-lua

COPY ./entrypoint.sh /root
WORKDIR /root
RUN chmod +x /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]

# RUN mkdir -p /opt/circonus/share/lua/5.1/
# COPY lua /opt/circonus/share/lua/5.1/
# ENV LUA_PATH /opt/circonus/share/lua/5.1/?.lua
ENV LUA_PATH /tree/lua/?.lua

CMD ["/bin/bash"]
