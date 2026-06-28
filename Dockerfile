from debian:trixie

run apt update \
	&& apt -y install openssh-server nano unzip wget curl psmisc net-tools aria2 nginx lrzsz tmux fish \
	&& sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config \
	&& mkdir -p /run/sshd \
	&& chmod -R 700 /run/sshd \
	&& chown -R root:users /run/sshd \
	&& echo "root:root" | chpasswd \
	&& apt clean \
	&& apt autoremove

copy ./installer /opt/installer

#ttyd
run set -e \
       && DOWNLOAD=$(curl -s https://api.github.com/repos/tsl0922/ttyd/releases/latest | grep browser_download_url |grep ttyd.x86_64| cut -d'"' -f4) \
       && aria2c -x 10 -j 10 -k 1m $DOWNLOAD -o /usr/bin/ttyd.x86_64 \
       && chmod +x /usr/bin/ttyd.x86_64

# filebrowser                                                                                                                                                                                                                                                                
run mkdir /opt/filebrowser \                                                                                                                                                                                                                                                 
        && cd /opt/filebrowser\                                                                                                                                                                                                                                              
        && DOWNLOAD=$(curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep browser_download_url |grep linux|grep amd64| grep -v rocm| cut -d'"' -f4) \                                                                                        
        && aria2c -x 10 -j 10 -k 1M $DOWNLOAD -o linux-amd64-filebrowser.tar.gz \                                                                                                                                                                                            
        && tar -zxvf linux-amd64-filebrowser.tar.gz \                                                                                                                                                                                                                        
        && rm -rf linux-amd64-filebrowser.tar.gz \                                                                                                                                                                                                                           
        && ln -s $(pwd)/filebrowser /usr/bin/filebrowser

#trzsz
run set -e \                                                                                                                                                                                                                                                                 
        && mkdir /opt/trzsz && cd /opt/trzsz \                     
        && DOWNLOAD=$(curl -s https://api.github.com/repos/trzsz/trzsz-go/releases/latest | grep browser_download_url |grep linux_x86_64|grep tar| cut -d'"' -f4) \
        && aria2c -x 10 -j 10 -k 1m $DOWNLOAD -o bin.tar.gz \
        && tar -zxvf bin.tar.gz \                                  
        && rm -rf bin.tar.gz \                                     
        && BIN_DIR=$(pwd)/$(ls -A .) \          
        && ln -s $BIN_DIR/trzsz /usr/bin/trzsz \                   
        && ln -s $BIN_DIR/trz /usr/bin/trz \                       
        && ln -s $BIN_DIR/tsz /usr/bin/tsz

# uv                                                                                                                                                                                                              
RUN echo install-uv && set -e \                                                                                                                                                                                   
        && mkdir /opt/uv \                                                                                                                                                                                        
        && cd /opt/uv \                                                                                                                                                                                           
        && echo fetch-uv-url && DOWNLOAD=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | grep browser_download_url |grep linux|grep x86_64| grep -v rocm| cut -d'"' -f4) \                  
        && echo fetch-uv-bin && aria2c -x 10 -j 10 -k 1M ${DOWNLOAD:-https://releases.astral.sh/github/uv/releases/download/0.11.21/uv-x86_64-unknown-linux-gnu.tar.gz} -o uv.tar.gz \                            
        && echo unpack-uv-bin && tar -zxvf uv.tar.gz \                                                                                                                                                            
        && rm -rf uv.tar.gz \                                                                                                                                                                                     
        && PATH_FRAG=$(pwd)/$(ls -A .) \                                                                                                                                                                          
        && ln -s $PATH_FRAG/uv /usr/bin/uv \                                                                                                                                                                      
        && ln -s $PATH_FRAG/uvx /usr/bin/uvx

# openmoss tts nano
RUN set -e \
        && apt install -y git \
	&& uv venv --python 3.13 /opt/venv

RUN set -e \
        && git clone https://github.com/OpenMOSS/MOSS-TTS-Nano.git /opt/MOSS-TTS-Nano.git

# UV INSTALL
RUN set -e \
	&& . /opt/venv/bin/activate \
	&& cd /opt/MOSS-TTS-Nano.git \
	&& uv pip install -r requirements.txt \
	&& uv pip install -e .

run rm -rf /etc/nginx/sites-enabled/default
add ./NGINX /etc/nginx/sites-enabled/
run sed -i "s/# alias/alias/g" /root/.bashrc
env ROOT_PASSWORD=
copy ./docker-entrypoint.sh /
run chmod +x /docker-entrypoint.sh
cmd []
volume ["/root"]
volume ["/opt/installer"]
volume ["/workspace"]
entrypoint ["/docker-entrypoint.sh"]
