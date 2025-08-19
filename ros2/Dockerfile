FROM osrf/ros:jazzy-desktop

RUN apt-get update && apt-get install -y \
  fish \
  vim \
  git \
  less \
  sudo \
  tmux \
  fzf \
  lsof \
  ccache \
  && rm -rf /var/lib/apt/lists/*

# RUN echo "tatzv ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# RUN useradd -ms /usr/bin/bash tatzv
# USER tatzv

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc

WORKDIR /root/ros_ws

CMD ["bash"]
