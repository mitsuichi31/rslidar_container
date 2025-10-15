USER_NAME=user
WORKSPACE=devel

xhost local:
docker run --rm -it --privileged \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v /etc/localtime:/etc/localtime \
        -v /home/$USER_NAME/$WORKSPACE:/$USER_NAME/$WORKSPACE \
        -v /home/$USER_NAME/docker:/$USER_NAME/docker \
        -e DISPLAY=$DISPLAY \
        --network host \
        --name ubuntu2204docker-rslidar \
        ubuntu2204docker:rslidar_sdk