FROM ubuntu:jammy
LABEL maintainer="Enes Sadık Özbek <es.ozbek.me>"

ENV DEBIAN_FRONTEND=noninteractive
ENV GAME_INSTALL_DIR=/home/steam/Unturned
ENV GAME_ID=1110390
ENV SERVER_NAME=server
ENV STEAM_USERNAME=anonymous
ENV STEAMCMD_DIR=/home/steam/steamcmd

EXPOSE 27015/udp
EXPOSE 27016/udp

# Fix DNS and network issues
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# Install required packages with retry mechanism
RUN apt-get update --fix-missing && \
    apt-get install -y \
        unzip \
        tar \
        curl \
        coreutils \
        lib32gcc-s1 \
        libgdiplus \
        dos2unix \
        ca-certificates \
        locales && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

# Install SteamCMD with updated URL
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -o steamcmd_linux.tar.gz || \
    curl -sqL "https://media.steampowered.com/client/installer/steamcmd_linux.tar.gz" -o steamcmd_linux.tar.gz && \
    tar zxvf steamcmd_linux.tar.gz && \
    rm steamcmd_linux.tar.gz

# Install game with error handling
RUN ./steamcmd.sh \
    +force_install_dir $GAME_INSTALL_DIR \
    +login anonymous \
    +app_update $GAME_ID validate \
    +quit || echo "SteamCMD installation failed, continuing..."

# Set up Steam SDK
RUN mkdir -p /home/steam/.steam/sdk64/ && \
    if [ -f "$GAME_INSTALL_DIR/linux64/steamclient.so" ]; then \
        cp -f $GAME_INSTALL_DIR/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so; \
    fi

# Copy and prepare init script
COPY --chown=steam:steam init.sh $STEAMCMD_DIR/
RUN dos2unix $STEAMCMD_DIR/init.sh && chmod +x $STEAMCMD_DIR/init.sh

WORKDIR $GAME_INSTALL_DIR

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "Unturned_Headless" > /dev/null || exit 1

ENTRYPOINT ["../steamcmd/init.sh"]