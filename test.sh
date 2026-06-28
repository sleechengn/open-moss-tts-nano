#!/usr/bin/env bash
container_id=$(docker run -itd -p 18083:18083 --rm 192.168.13.73:5000/sleechengn/openmoss-tts-nano:latest)
docker attach $container_id
