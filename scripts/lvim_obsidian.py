#!/bin/python3
"""This script is used to open the file in the kitty terminal."""
import subprocess
import time

import pyperclip
from pynput import keyboard


def main():
    """Initialise."""
    controller = keyboard.Controller()

    # alt-p to copy file's path
    controller.press(keyboard.Key.alt)
    controller.press("p")
    controller.release("p")
    controller.release(keyboard.Key.alt)
    # Wait a bit
    time.sleep(0.2)
    # Get the link
    link = str(pyperclip.paste())
    subprocess.Popen(
        f'kitty nvim -u ~/.config/nvim/lua/init_latex.lua "/home/rad1an/Drive/conspectus/Conspectus/{link}"',
        shell=True,
    )
    time.sleep(0.8)
    # Super+left to tile left
    controller.press(keyboard.Key.cmd)
    controller.press(keyboard.Key.left)
    controller.release(keyboard.Key.left)
    controller.release(keyboard.Key.cmd)


if __name__ == "__main__":
    main()
