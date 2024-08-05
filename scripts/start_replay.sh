#!/bin/sh
flatpak run --command=gpu-screen-recorder com.dec05eba.gpu_screen_recorder -w portal -f 60 -c mp4 -r 30 -a default_output -a default_input -o ~/Videos/GPUScreenRecorder/ -restore-portal-session yes
