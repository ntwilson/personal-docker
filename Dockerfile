FROM mcr.microsoft.com/dotnet/sdk:9.0 AS dotenv

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    build-essential \
    bzip2 \
    curl \
    dos2unix \
    git \
    gnupg \
    libbz2-dev \
    libffi-dev \
    liblzma-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxmlsec1-dev \
    pipx \
    python3-pip \
    software-properties-common \
    sudo \
    tk-dev \
    unzip \
    wget \
    xz-utils \
    zlib1g-dev

RUN mkdir /gitconfigvolume && \
    touch /gitconfigvolume/.gitconfig && \
    ln -s /gitconfigvolume/.gitconfig /root/.gitconfig

ENV PATH="$PATH:/usr/bin/git:/root/.dotnet/tools"

# install github cli
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && \
    apt install gh -y

# install SQL ODBC drivers
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EB3E94ADBE1229CF && \
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install msodbcsql17 --assume-yes

# install sqlcmd
RUN curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc && \
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/prod.list)" && \
    apt-get update && \
    apt-get install sqlcmd

# install python
ENV PYENV_ROOT=/root/.pyenv
ENV PATH="$PATH:$PYENV_ROOT/bin:$PYENV_ROOT/shims"
RUN curl https://pyenv.run | bash && \
    eval "$(pyenv init -)" && \
    pyenv install 3.12.4 && \
    pyenv global 3.12.4 && \
    pipx ensurepath && \
    pipx install pdm
  

# install nvm, nodejs
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install 20.15.0

ENV PATH="$PATH:/root/.nvm/versions/node/v20.15.0/bin"

# install powershell
# https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.4
RUN . /etc/os-release && \
    wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell

# install az cli
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Add the pdm install directory to path
ENV PATH="$PATH:/root/.local/bin"
RUN dotnet tool install --global paket
RUN pwsh -c "Install-Module -Name SqlServer -Scope CurrentUser -Force" && \
    pwsh -c "Install-Module -Name Az -Scope CurrentUser -Force" && \
    pwsh -c "Install-Module -Name dbatools -Scope CurrentUser -Force" && \
    pwsh -c "Install-Module -Name pwsh-dotenv -Scope CurrentUser -Force" && \
    pwsh -c "Set-DbatoolsInsecureConnection"

COPY ./OneTimeSetup.ps1 /root/OneTimeSetup.ps1
RUN dos2unix /root/OneTimeSetup.ps1

ENV DOTNET_NEW_PREFERRED_LANG="F#"

WORKDIR /workspace

