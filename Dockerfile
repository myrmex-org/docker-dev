# Use ubuntu:latest as base image.
FROM ubuntu:latest

MAINTAINER Alexis N-o "alexis@henaut.net"

ENV LANG=C.UTF-8
ENV NODE_VERSION=6.10.3
ENV DEFAULT_USER=myrmex

# Install useful packages for a Node.js development environment
RUN apt-get update &&\
    apt-get install -y sudo apt-transport-https ca-certificates software-properties-common python-software-properties python g++ make zsh curl wget git unzip vim telnet &&\
    apt-get clean && rm -rf /var/lib/apt/lists/* &&\
    cd /opt &&\
    wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz &&\
    tar xvzf node-v${NODE_VERSION}-linux-x64.tar.gz &&\
    ln -s /opt/node-v${NODE_VERSION}-linux-x64/bin/node /usr/local/bin/node &&\
    ln -s /opt/node-v${NODE_VERSION}-linux-x64/bin/npm /usr/local/bin/npm &&\
    curl -O https://bootstrap.pypa.io/get-pip.py &&\
    python get-pip.py

# Install Docker. Indeed, we want to be able to run docker in docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&\
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&\
    apt-get update &&\
    apt-get install -y docker-ce &&\
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install oh-my-zsh and define zsh as default shell
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true &&\
    chsh -s /bin/zsh

# Apply custom theme, disable auto-update and fix backspace displaying space in the prompt
COPY /.oh-my-zsh/themes/myrmex.zsh-theme /root/.oh-my-zsh/themes/myrmex.zsh-theme
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="myrmex"/g' /root/.zshrc &&\
    sed -i 's/# DISABLE_AUTO_UPDATE=true/DISABLE_AUTO_UPDATE=true/g' /root/.zshrc &&\
    echo TERM=xterm >> /root/.zshrc

# Add a script to modify the UID / GID for the default user if needed
COPY /usr/local/bin/change-uid /usr/local/bin/change-uid
RUN chmod +x /usr/local/bin/change-uid

# Add entrypoint
COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh"]

# Create user "myrmex"
RUN useradd $DEFAULT_USER -m -d /home/$DEFAULT_USER/ -s /bin/zsh -G sudo && passwd -d -u $DEFAULT_USER

# Configure zsh and git for user "myrmex"
USER $DEFAULT_USER
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true &&\
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="myrmex"/g' /home/$DEFAULT_USER/.zshrc &&\
    sed -i 's/# DISABLE_AUTO_UPDATE=true/DISABLE_AUTO_UPDATE=true/g' /home/$DEFAULT_USER/.zshrc &&\
    echo TERM=xterm >> /home/$DEFAULT_USER/.zshrc
COPY /.oh-my-zsh/themes/myrmex.zsh-theme /home/$DEFAULT_USER/.oh-my-zsh/themes/myrmex.zsh-theme

# Set zsh history in a directory so it can be persisted with a volume
RUN mkdir /home/$DEFAULT_USER/.zsh_history
ENV HISTFILE /home/$DEFAULT_USER/.zsh_history/history

# Setup to install npm packages globally with user myrmex
RUN echo "prefix = ~/.node" >> ~/.npmrc &&\
    echo "export PATH=$PATH:/home/$DEFAULT_USER/.node/bin/" >> ~/.zshrc
ENV PATH $PATH:/home/$DEFAULT_USER/.node/bin/

# Common packages for tests
RUN npm install -g mocha istanbul bunyan myrmex

# Create a directory to share the application sources
ENV WORKDIR /home/$DEFAULT_USER/app
RUN mkdir $WORKDIR
WORKDIR $WORKDIR

CMD ["zsh"]
