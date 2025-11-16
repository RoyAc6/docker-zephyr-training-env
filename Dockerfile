FROM ubuntu:22.04

# ---------- Build-time arguments ----------
ARG USERNAME=trainee
ARG PASSWORD=Ac6@training
ARG VNC_PORT=5901
ARG NO_VNC_PORT=8080
ARG RESOLUTION=1920x1080

# ---------- Runtime environment ----------
ENV DEBIAN_FRONTEND=noninteractive \
    USERNAME=${USERNAME} \
    PASSWORD=${PASSWORD} \
    DISPLAY=:1 \
    VNC_PORT=${VNC_PORT} \
    NO_VNC_PORT=${NO_VNC_PORT} \
    RESOLUTION=${RESOLUTION}

# ---------- Base system + XFCE + Zephyr dependencies ----------
RUN apt-get update && apt-get install -y \
    apt-utils sudo \
    xfce4 xfce4-goodies xfconf xfce4-session \
    novnc websockify \
    tigervnc-standalone-server tigervnc-common \
    dbus-x11 x11-xserver-utils \
    wget curl gnupg2 software-properties-common apt-transport-https \
    nano gedit htop net-tools iproute2 iputils-ping \
    # Zephyr deps
    git gperf ccache dfu-util wget xz-utils unzip file make \
    libsdl2-dev libmagic1 \
    cmake ninja-build device-tree-compiler \
    python3-dev python3-pip python3-venv python3-setuptools python3-tk python3-wheel \
    gcc gcc-multilib g++-multilib build-essential libssl-dev libffi-dev cargo \
    && apt-get remove -y xfce4-power-manager \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- VSCode (Microsoft repo) ----------
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && apt-get update && apt-get install -y code \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- Create user ----------
RUN useradd -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME}:${PASSWORD}" | chpasswd \
    && usermod -aG sudo ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ---------- Falkon browser ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
      falkon xdg-utils at-spi2-core && \
    update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/falkon 100 && \
    update-alternatives --set x-www-browser /usr/bin/falkon && \
    echo 'export BROWSER=/usr/bin/falkon' > /etc/profile.d/browser.sh && \
    install -d -m 0755 /home/${USERNAME}/Desktop && \
    cp /usr/share/applications/org.kde.falkon.desktop /home/${USERNAME}/Desktop/falkon.desktop && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/Desktop/falkon.desktop && \
    chmod +x /home/${USERNAME}/Desktop/falkon.desktop && \
    rm -rf /var/lib/apt/lists/*

# ---------- VNC password ----------
RUN mkdir -p /home/${USERNAME}/.vnc \
    && echo "${PASSWORD}" | vncpasswd -f > /home/${USERNAME}/.vnc/passwd \
    && chmod 600 /home/${USERNAME}/.vnc/passwd \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.vnc

# ---------- xstartup to fix logout issue ----------
RUN echo '#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
exec dbus-launch --exit-with-session startxfce4\n' \
> /home/${USERNAME}/.vnc/xstartup && \
    chmod +x /home/${USERNAME}/.vnc/xstartup && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.vnc/xstartup

# ---------- Resources ----------
COPY resources/ac6-onlinepc-wallpaper.jpg /usr/share/backgrounds/xfce/ac6-onlinepc-wallpaper.jpg
COPY resources/xfce4-desktop.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
COPY resources/xfce4-desktop.xml /home/${USERNAME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
COPY resources/vscode.desktop /home/${USERNAME}/Desktop/vscode.desktop
COPY resources/traceviewer.desktop /home/${USERNAME}/Desktop/traceviewer.desktop
COPY resources/startup.sh /startup.sh

RUN chmod +x /startup.sh && \
    chmod 644 /usr/share/backgrounds/xfce/ac6-onlinepc-wallpaper.jpg && \
    chown root:root /usr/share/backgrounds/xfce/ac6-onlinepc-wallpaper.jpg && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config && \
    chmod 644 /home/${USERNAME}/.config/xfce4/xfconf/xfce-perchannel-xml/*.xml && \
    chmod +x /home/${USERNAME}/Desktop/vscode.desktop /home/${USERNAME}/Desktop/traceviewer.desktop && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/Desktop

# ---------- XFCE panel defaults ----------
RUN sed -i "s|TerminalEmulator=.*|TerminalEmulator=xfce4-terminal|" /etc/xdg/xfce4/helpers.rc && \
    sed -i "s|WebBrowser=.*|WebBrowser=falkon|" /etc/xdg/xfce4/helpers.rc

# ---------- noVNC setup ----------
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# ---------- Percepio Tracealyzer ----------
RUN wget https://download.tracealyzer.io/PercepioViewForZephyr-4.10.3-linux-standalone-x86-64.tgz -O /tmp/trace.tgz && \
    tar -xzf /tmp/trace.tgz -C /usr/share && \
    rm /tmp/trace.tgz && \
    mv /usr/share/PercepioViewForZephyr-4.10.3 /usr/share/PercepioViewForZephyr

# ---------- VS Code extensions ----------
USER ${USERNAME}
ENV VSCODE_CLI="/usr/bin/code" \
    VSCODE_EXTENSIONS_DIR="/home/${USERNAME}/.vscode/extensions"

RUN ${VSCODE_CLI} --install-extension Ac6.zephyr-workbench && \
    ${VSCODE_CLI} --install-extension Ac6.zazu-simulator && \
    /bin/bash ${VSCODE_EXTENSIONS_DIR}/ac6.zephyr-workbench-*/scripts/hosttools/install.sh --skip-sdk --only-without-root /home/${USERNAME} && \
    /bin/bash ${VSCODE_EXTENSIONS_DIR}/ac6.zazu-*/scripts/zazuDependenciesInstaller.sh /home/${USERNAME}/.ac6-zazu

# ---------- Final setup ----------
WORKDIR /home/${USERNAME}
EXPOSE ${NO_VNC_PORT}
CMD ["/startup.sh"]

