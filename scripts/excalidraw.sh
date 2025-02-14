cd $HOME/Desktop/excalidraw/ && podman compose up -d && sh -c 'XAPP_FORCE_GTKWINDOW_ICON="/home/rad1an/.local/share/ice/icons/Excalidraw.png" firefox --class WebApp-Excalidraw4852 --name WebApp-Excalidraw4852 --profile /home/rad1an/.local/share/ice/firefox/Excalidraw4852 --no-remote "http://localhost:3000/"'
podman compose down
