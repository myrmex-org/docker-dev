# Use ubuntu:latest as base image.
FROM ubuntu:latest

MAINTAINER Alexis N-o "alexis@henaut.net"

ENV NODE_VERSION=4.4.7
ENV DEFAULT_USER=lager

# Install useful packages for a Node.js development environment
RUN apt-get update &&\
    apt-get install -y sudo software-properties-common python-software-properties python g++ make zsh curl wget git unzip vim telnet &&\
    apt-get clean && rm -rf /var/lib/apt/lists/* &&\
    cd /opt &&\
    wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz &&\
    tar xvzf node-v${NODE_VERSION}-linux-x64.tar.gz &&\
    ln -s /opt/node-v${NODE_VERSION}-linux-x64/bin/node /usr/local/bin/node &&\
    ln -s /opt/node-v${NODE_VERSION}-linux-x64/bin/npm /usr/local/bin/npm

# Install oh-my-zsh and define zsh as default shell
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true &&\
    chsh -s /bin/zsh

# Apply custom theme, disable auto-update and fix backspace displaying space in the prompt
COPY /.oh-my-zsh/themes/lager.zsh-theme /root/.oh-my-zsh/themes/lager.zsh-theme
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="lager"/g' /root/.zshrc &&\
    sed -i 's/# DISABLE_AUTO_UPDATE=true/DISABLE_AUTO_UPDATE=true/g' /root/.zshrc &&\
    echo TERM=xterm >> /root/.zshrc

# Add a script to modify the UID / GID for the default user if needed
COPY /usr/local/bin/change-uid /usr/local/bin/change-uid
RUN chmod +x /usr/local/bin/change-uid

# Add entrypoint
COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh"]

# Create user "lager"
RUN useradd $DEFAULT_USER -m -d /home/$DEFAULT_USER/ -s /bin/zsh -G sudo && passwd -d -u $DEFAULT_USER

# Configure zsh and git for user "lager"
USER $DEFAULT_USER
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true &&\
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="lager"/g' /home/$DEFAULT_USER/.zshrc &&\
    sed -i 's/# DISABLE_AUTO_UPDATE=true/DISABLE_AUTO_UPDATE=true/g' /home/$DEFAULT_USER/.zshrc &&\
    echo TERM=xterm >> /home/$DEFAULT_USER/.zshrc
COPY /.oh-my-zsh/themes/lager.zsh-theme /home/$DEFAULT_USER/.oh-my-zsh/themes/lager.zsh-theme

# Setup to install npm packages globally with user lager
RUN echo "prefix = ~/.node" >> ~/.npmrc &&\
    echo "export PATH=$PATH:/home/$DEFAULT_USER/.node/bin/" >> ~/.zshrc
ENV PATH $PATH:/home/$DEFAULT_USER/.node/bin/

# Common packages for tests
RUN npm install -g mocha istanbul bunyan @lager/cli

# Create this directory so it will not belongs to the root user when we mount volumes here
RUN mkdir /home/lager/.node/lib/node_modules/@lager

# Create symlink to enable the Lager cli
RUN cd ~/.node/bin && ln -s ../lib/node_modules/@lager/cli/src/bin/lager lager

# Create a directory to share the application sources
ENV WORKDIR /home/$DEFAULT_USER/app
RUN mkdir $WORKDIR
WORKDIR $WORKDIR

CMD ["zsh"]
