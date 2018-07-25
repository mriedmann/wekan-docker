FROM ubuntu:bionic
MAINTAINER michael_riedmann@live.com

ENV WEKAN_VERSION=0.94
ENV BUILD_DEPS="bsdtar wget curl bzip2 build-essential python git ca-certificates gcc-7"
ENV NODE_VERSION=v8.11.3
ENV NODE_VERSION_CHECKSUM="40e7990489c13a1ed1173d8fe03af258c6ed964b92a4bd59a0927ac5931054aa"
ENV METEOR_RELEASE=1.6.0.1
ENV METEOR_EDGE=1.5-beta.17
ENV NPM_VERSION=6.2.0
ENV FIBERS_VERSION=2.0.0
ENV ARCHITECTURE=linux-x64

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends ${BUILD_DEPS} && \
    rm -R /var/lib/apt/lists/*

# Download patched wekan nodejs (fixes 100% CPU bug)
RUN cd /tmp/ && \
    wget https://releases.wekan.team/node-${NODE_VERSION}-${ARCHITECTURE}.tar.gz && \
    echo "${NODE_VERSION_CHECKSUM}  node-v8.11.3-linux-x64.tar.gz" >> SHASUMS256.txt.asc && \
    grep ${NODE_VERSION}-${ARCHITECTURE}.tar.gz SHASUMS256.txt.asc | shasum -a 256 -c - && rm -f SHASUMS256.txt.asc && \
    tar xvzf node-${NODE_VERSION}-${ARCHITECTURE}.tar.gz && \
    rm node-${NODE_VERSION}-${ARCHITECTURE}.tar.gz && \
    mv node-${NODE_VERSION}-${ARCHITECTURE} /opt/nodejs && \
    ln -s /opt/nodejs/bin/node /usr/bin/node && \
    ln -s /opt/nodejs/bin/npm /usr/bin/npm

# Install Node dependencies
RUN npm install -g npm@${NPM_VERSION}
RUN npm install -g node-gyp
RUN npm install -g fibers@${FIBERS_VERSION}

# meteor install tar-fix
RUN mv /bin/tar /bin/tar.gnu && \
    ln -s /usr/bin/bsdtar /bin/tar

# add wekan user
RUN mkdir /home/wekan &&  useradd --user-group --system --home-dir /home/wekan wekan

RUN mkdir /build && \
    chown -R wekan:wekan /home/wekan && \
    chown -R wekan:wekan /build

WORKDIR /home/wekan
USER wekan

# Install meteor
RUN curl https://install.meteor.com -o install_meteor.sh && \
    sed -i "s|RELEASE=.*|RELEASE=${METEOR_RELEASE}\"\"|g" ./install_meteor.sh && \
    sh install_meteor.sh && \
    rm install_meteor.sh

# Get additional packages
RUN mkdir -p app/packages && \
    git clone --depth 1 -b master https://github.com/wekan/flow-router.git app/packages/kadira-flow-router && \
    git clone --depth 1 -b master https://github.com/meteor-useraccounts/core.git app/packages/meteor-useraccounts-core && \
    sed -i 's/api\.versionsFrom/\/\/api.versionsFrom/' app/packages/meteor-useraccounts-core/package.js

RUN cd /tmp/ && \
    curl https://codeload.github.com/wekan/wekan/tar.gz/v${WEKAN_VERSION} | tar -xzf -  && \
    mv /tmp/wekan-${WEKAN_VERSION}/* /home/wekan/app/ && \
    mv /tmp/wekan-${WEKAN_VERSION}/.[!.]* /home/wekan/app/

# build app
WORKDIR /home/wekan/app

RUN ~/.meteor/meteor add standard-minifier-js --allow-superuser
RUN ~/.meteor/meteor npm install --allow-superuser
RUN ~/.meteor/meteor build --directory ~/app_build

RUN chown -R wekan:wekan ~/app_build/
RUN cp -f fix-download-unicode/cfs_access-point.txt ~/app_build/bundle/programs/server/packages/cfs_access-point.js
RUN sh -c 'cd ~/app_build/bundle/programs/server/ && npm install'

RUN mv /home/wekan/app_build/bundle/* /build/

# Cleanup
USER root
RUN rm /bin/tar && \
    mv /bin/tar.gnu /bin/tar && \
    apt-get remove --purge -y ${BUILD_DEPS} && \
    apt-get autoremove -y && \
    rm -R /var/lib/apt/lists/* && \
    rm -R /home/wekan/.meteor && \
    rm -R /home/wekan/app && \
    rm -R /home/wekan/app_build

USER wekan
ENV PORT=8080
EXPOSE $PORT

CMD ["node", "/build/main.js"]