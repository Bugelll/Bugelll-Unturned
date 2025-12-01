FROM ubuntu:jammy
LABEL maintainer="Emqo Freeyohurt <gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV GAME_INSTALL_DIR=/home/steam/Unturned
ENV GAME_ID=1110390
ENV SERVER_NAME=server
ENV STEAM_USERNAME=anonymous
ENV STEAMCMD_DIR=/home/steam/steamcmd

# 注意：端口映射在 docker-compose.yml 中配置，不在此处声明
# 这样可以灵活配置不同的端口映射

# Install required packages with better error handling
# 合并RUN命令以减少镜像层数，提高构建效率
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
        procps && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # 验证关键工具安装
    which unzip && which tar && which curl

# Set up locale to fix SteamCMD warnings
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

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

# Health check - 检查Unturned进程是否运行
# 使用procps包中的pgrep命令（已在依赖中安装）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "Unturned_Headless" > /dev/null || exit 1

ENTRYPOINT ["../steamcmd/init.sh"]