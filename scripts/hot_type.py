#!/usr/bin/python
import click
import time
import pyperclip
from pynput import keyboard


@click.command()
@click.option("--type", default="text", help="Type of hotkey.")
@click.option("--data", default="-", help="Data of hotkey.")
def click(type, data):
    controller = keyboard.Controller()
    if type == "text":
        print("Text; data:", data)
        for char in data:
            print("Char:", char)
            controller.press(char)
            controller.release(char)
    if type == "clip":
        clip = pyperclip.paste()
        pyperclip.copy(data)
    if type == "paste":
        clip = pyperclip.paste()
        pyperclip.copy(data)
        controller.press(keyboard.Key.ctrl)
        controller.press("v")
        controller.release(keyboard.Key.ctrl)
        controller.release("v")
        time.sleep(1)
        pyperclip.copy(clip)


click()
