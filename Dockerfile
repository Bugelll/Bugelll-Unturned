FROM ubuntu:jammy
LABEL maintainer="Emqo Freeyohurt <gmail.com>"
LABEL org.opencontainers.image.description="Unturned game server with RocketMod support"
LABEL org.opencontainers.image.source="https://github.com/Bugelll/Bugelll-Unturned"

ENV DEBIAN_FRONTEND=noninteractive \
    GAME_INSTALL_DIR=/home/steam/Unturned \
    GAME_ID=1110390 \
    SERVER_NAME=server \
    STEAM_USERNAME=anonymous \
    STEAMCMD_DIR=/home/steam/steamcmd \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install required packages in a single layer for better caching
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
        unzip \
        tar \
        curl \
        coreutils \
        lib32gcc-s1 \
        libgdiplus \
        dos2unix \
        ca-certificates \
        locales \
        procps \
        tzdata && \
    locale-gen en_US.UTF-8 && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    which unzip && which tar && which curl

# Add Steam user
RUN adduser \
    --home /home/steam \
    --disabled-password \
    --shell /bin/bash \
    --gecos "user for running steam" \
    --quiet \
    steam

# Create directories
RUN mkdir -p $STEAMCMD_DIR $GAME_INSTALL_DIR && \
    chown -R steam:steam /home/steam

# Switch to steam user early
USER steam
WORKDIR $STEAMCMD_DIR

# Install SteamCMD with fallback URLs
# 使用多个镜像源确保下载成功
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -o steamcmd_linux.tar.gz || \
    curl -sqL "https://media.steampowered.com/client/installer/steamcmd_linux.tar.gz" -o steamcmd_linux.tar.gz || \
    curl -sqL "https://repo.steampowered.com/steamcmd/linux/steamcmd_linux.tar.gz" -o steamcmd_linux.tar.gz && \
    tar zxvf steamcmd_linux.tar.gz && \
    rm -f steamcmd_linux.tar.gz && \
    # 验证SteamCMD安装
    test -f ./steamcmd.sh && chmod +x ./steamcmd.sh

# Copy and prepare init script
COPY --chown=steam:steam init.sh $STEAMCMD_DIR/
RUN dos2unix $STEAMCMD_DIR/init.sh && chmod +x $STEAMCMD_DIR/init.sh

WORKDIR $GAME_INSTALL_DIR

# Health check - Check if Unturned process is running
# Uses pgrep from procps package (already installed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -f "Unturned_Headless" > /dev/null || exit 1

ENTRYPOINT ["../steamcmd/init.sh"]