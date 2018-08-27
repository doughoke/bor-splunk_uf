FROM blacktop/bro

#taken from https://github.com/splunk/docker-splunk/blob/master/universalforwarder/Dockerfile
ENV SPLUNK_PRODUCT universalforwarder
ENV SPLUNK_VERSION 7.1.2
ENV SPLUNK_BUILD a0c72a66db66
ENV SPLUNK_FILENAME splunkforwarder-${SPLUNK_VERSION}-${SPLUNK_BUILD}-Linux-x86_64.tgz

ENV SPLUNK_HOME /opt/splunk
ENV SPLUNK_GROUP splunk
ENV SPLUNK_USER splunk
ENV SPLUNK_BACKUP_DEFAULT_ETC /var/opt/splunk
ARG DEBIAN_FRONTEND=noninteractive

#moved above original cplunk entrypoint location
RUN apk --update add 

#&& apk add -y locales && rm -rf /var/lib/apt/lists/* \
#	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

#add shadow package for alpine useradd and groupadd
RUN apk add --no-cache shadow outils-md5
ENV LANG en_US.utf8

# add splunk:splunk user
RUN groupadd -r ${SPLUNK_GROUP} \
    && useradd -r -m -g ${SPLUNK_GROUP} ${SPLUNK_USER}

# make the "en_US.UTF-8" locale so splunk will be utf-8 enabled by default
#RUN apk update && apk install -y locales \
#    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
#ENV LANG en_US.utf8



# Download official Splunk release, verify checksum and unzip in /opt/splunk
# Also backup etc folder, so it will be later copied to the linked volume
RUN apk update && apk add wget sudo

RUN mkdir -p ${SPLUNK_HOME} \
    && wget -qO /tmp/${SPLUNK_FILENAME} https://download.splunk.com/products/${SPLUNK_PRODUCT}/releases/${SPLUNK_VERSION}/linux/${SPLUNK_FILENAME} \
    && wget -qO /tmp/${SPLUNK_FILENAME}.md5 https://download.splunk.com/products/${SPLUNK_PRODUCT}/releases/${SPLUNK_VERSION}/linux/${SPLUNK_FILENAME}.md5 

RUN ls -al /tmp

#RUN cat /tmp/${SPLUNK_FILENAME}.md5

#RUN md5sum /tmp/${SPLUNK_FILENAME} && md5sum -c /tmp/${SPLUNK_FILENAME}.md5


#RUN (cd /tmp && md5sum -c /tmp/${SPLUNK_FILENAME}.md5) 
    
RUN tar xzf /tmp/${SPLUNK_FILENAME} --strip 1 -C ${SPLUNK_HOME} \
    && rm /tmp/${SPLUNK_FILENAME} \
    && rm /tmp/${SPLUNK_FILENAME}.md5 \
    && mkdir -p /var/opt/splunk \
    && cp -R ${SPLUNK_HOME}/etc ${SPLUNK_BACKUP_DEFAULT_ETC} \
    && rm -fR ${SPLUNK_HOME}/etc \
    && chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME} \
    && chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_BACKUP_DEFAULT_ETC} \
    && rm -rf /var/lib/apt/lists/*

COPY bro-suf-entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

# Ports Splunk Daemon, Network Input, HTTP Event Collector
EXPOSE 8089/tcp 1514 8088/tcp

WORKDIR /opt/splunk

# Configurations folder, var folder for everyting (indexes, logs, kvstore)
VOLUME [ "/opt/splunk/etc", "/opt/splunk/var" ]

#ENTRYPOINT ["/sbin/entrypoint.sh"]
#CMD ["start-service"]