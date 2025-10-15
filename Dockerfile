FROM ros:humble

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q && \
    apt-get upgrade -yq && \
    apt-get install -yq \
            wget \
            curl \
            git \
            build-essential \
            vim \
            sudo \
            lsb-release \
            locales \
            bash-completion \
            glmark2 \
            tzdata
#             && \
#    rm -rf /var/lib/apt/lists/*

RUN apt-get install -y software-properties-common
# xterm
RUN add-apt-repository universe

# Add user account
ENV USER_NAME=user
ENV USER_PASS=user123

RUN useradd -m -d /home/${USER_NAME} ${USER_NAME} \
        -p $(perl -e 'print crypt("${USER_NAME}", "${USER_PASS}}"),"\n"') && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN locale-gen en_US.UTF-8
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}
ENV HOME=/home/${USER_NAME}
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

ENV ROS_DISTRO=humble

RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc

RUN sudo apt-get update && \
    sudo apt-get install -y \
        python3-pip && \
    pip install transforms3d

        # ros-${ROS_DISTRO}-joint-state-publisher-gui \
        # ros-${ROS_DISTRO}-navigation2 \
        # ros-${ROS_DISTRO}-nav2-bringup \
        # ros-${ROS_DISTRO}-robot-localization \
        # ros-${ROS_DISTRO}-ros-ign \
        # ros-${ROS_DISTRO}-ros-ign-bridge \
        # ros-${ROS_DISTRO}-tf-transformations \
        # ros-${ROS_DISTRO}-tf2 \
        # ros-${ROS_DISTRO}-tf2-ros \
        # ros-${ROS_DISTRO}-xacro && \

# RUN sudo apt-get install -y \
#         ros-${ROS_DISTRO}-gazebo-ros \
#         ros-${ROS_DISTRO}-ecl-threads \
#         ros-${ROS_DISTRO}-gazebo-ros-pkgs \
#         ros-${ROS_DISTRO}-gazebo-plugins \
#         ros-${ROS_DISTRO}-ros2-controllers \
#         ros-${ROS_DISTRO}-gazebo-ros2-control \
#         ros-${ROS_DISTRO}-ros2-control \
#         ros-${ROS_DISTRO}-joy \
#         ros-${ROS_DISTRO}-velodyne-gazebo-plugins

#RUN sudo apt-get install -y python3-rosdep
#RUN sudo rosdep init
RUN rosdep update

RUN sudo apt-get install -y libyaml-cpp-dev
RUN sudo apt-get install -y libpcap-dev
RUN sudo apt-get install -y ros-std-msgs

RUN pip install numpy-stl
# RUN sudo apt install -y ros-${ROS_DISTRO}-rqt-robot-steering
# RUN sudo apt install -y ros-${ROS_DISTRO}-joint-state-publisher-gui ros-${ROS_DISTRO}-robot-state-publisher ros-${ROS_DISTRO}-rviz2
RUN sudo apt install -y ros-${ROS_DISTRO}-rviz2
# RUN sudo apt install -y ros-${ROS_DISTRO}-slam-toolbox ros-${ROS_DISTRO}-teleop-twist-keyboard ros-${ROS_DISTRO}-rqt-graph
RUN sudo apt install -y ros-${ROS_DISTRO}-rmw-cyclonedds-cpp

RUN mkdir -p /home/${USER_NAME}/ros2_ws/src

# RUN cd /home/${USER_NAME}/ros2_ws/src && git clone https://github.com/RoboSense-LiDAR/rslidar_sdk.git
# RUN cd /home/${USER_NAME}/ros2_ws/src/rslidar_sdk && git submodule init && git submodule update
# RUN cd /home/${USER_NAME}/ros2_ws/src && git clone https://github.com/RoboSense-LiDAR/rslidar_msg.git
COPY src/rslidar_sdk /home/${USER_NAME}/ros2_ws/src/rslidar_sdk
COPY src/rslidar_msg /home/${USER_NAME}/ros2_ws/src/rslidar_msg
RUN cd /home/${USER_NAME}/ros2_ws && \
    rosdep install --from-paths src --ignore-src -r -y
RUN sudo chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/ros2_ws
WORKDIR /home/${USER_NAME}/ros2_ws
RUN ["/bin/bash", "-c", ". /opt/ros/${ROS_DISTRO}/setup.bash && colcon build"]
RUN echo "source /home/${USER_NAME}/ros2_ws/install/setup.bash" >> ~/.bashrc

RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc

# RUN sudo apt install -y terminator
# RUN mkdir -p /home/${USER_NAME}/.config/terminator
# COPY terminator-config /home/mitz/.config/terminator/config

# RUN sudo apt install -y net-tools

# ----------------------------------------------------
# 絶対パスで entrypoint.sh を作成
RUN echo "#!/bin/bash" > /home/${USER_NAME}/entrypoint.sh
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/${USER_NAME}/entrypoint.sh
RUN echo "source /home/${USER_NAME}/ros2_ws/install/setup.bash" >> /home/${USER_NAME}/entrypoint.sh
RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> /home/${USER_NAME}/entrypoint.sh
RUN echo 'exec "$@"' >> /home/${USER_NAME}/entrypoint.sh

# 実行権限と所有権の変更
RUN chmod +x /home/${USER_NAME}/entrypoint.sh
RUN chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/entrypoint.sh

# ----------------------------------------------------
# ENTRYPOINT と CMD の設定
# ENTRYPOINT で実行ファイルを固定
ENTRYPOINT ["/home/user/entrypoint.sh"]

# CMD でデフォルト実行コマンドを設定（entrypoint.sh内の exec "$@" で実行される）
CMD ["ros2", "launch", "rslidar_sdk", "start_node.py"]
# CMD ["bash"]
