# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM gcr.io/kctf-docker/challenge@sha256:eb0f8c3b97460335f9820732a42702c2fa368f7d121a671c618b45bbeeadab28

RUN apt-get update && apt-get install -y gnupg2 wget

# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer installs, work.
# Deps from https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#chrome-headless-doesnt-launch-on-unix
#  plus libxshmfence1 which seems to be missing
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && wget -q -O - https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        ca-certificates \
        fonts-liberation \
        libappindicator3-1 \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgbm1 \
        libgcc1 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxshmfence1 \
        libxss1 \
        libxtst6 \
        lsb-release \
        wget \
        xdg-utils \
        nodejs \
        socat \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/user
COPY bot.js .
COPY flag1.txt .
COPY flag2.txt .
RUN tmpdir="/home/user/$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10)/flag-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10).txt" && mkdir -p $tmpdir && mv flag2.txt $tmpdir
COPY ext/ ./ext/
COPY .puppeteerrc.cjs .
RUN npm install puppeteer

ENV DOMAIN="pwnypass.c.hc.lc"
# Hosting multiple web challenges same-site to each other can lead to
# unintended solutions. E.g. an xss on a.foo.com will be able to overwrite
# cookies on b.foo.com.
# To prevent this, we can block chrome from accessing any subdomains under
# foo.com except for the real challenge domain using a PAC script.
# Unfortunately, PAC will not work in chrome headless mode, so this will use
# more resources.
ENV BLOCK_SUBORIGINS="1"
ENV REGISTERED_DOMAIN="c.hc.lc"

RUN if [ "${BLOCK_SUBORIGINS}" = "1" ]; then \
      apt-get update \
      && apt-get install -yq --no-install-recommends xvfb \
      && rm -rf /var/lib/apt/lists/*; \
    fi

CMD kctf_setup && \
    mount -t tmpfs none /tmp && \
    mkdir /tmp/chrome-userdata && chmod o+rwx /tmp/chrome-userdata && \
    while true; do \
      if [ "${BLOCK_SUBORIGINS}" = "1" ]; then \
        kctf_drop_privs env BLOCK_SUBORIGINS="${BLOCK_SUBORIGINS}" DOMAIN="${DOMAIN}" REGISTERED_DOMAIN="${REGISTERED_DOMAIN}" xvfb-run /usr/bin/node /home/user/bot.js; \
      else \
        kctf_drop_privs env BLOCK_SUBORIGINS="${BLOCK_SUBORIGINS}" DOMAIN="${DOMAIN}" REGISTERED_DOMAIN="${REGISTERED_DOMAIN}" /usr/bin/node /home/user/bot.js; \
      fi; \
    done & \
    kctf_drop_privs \
    socat \
      TCP-LISTEN:1337,reuseaddr,fork \
      EXEC:"kctf_pow socat STDIN TCP\:localhost\:1338"