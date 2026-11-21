#!/usr/bin/env python3
"""Tray indicator for the three backup timers.

Hover shows the newest backup date. Click opens a frameless popup with text
status and a refresh icon beside each backup.

This is the PyQt5 version that previously opened successfully. The only change
from that version is the removal of WA_DeleteOnClose, which caused the
RuntimeError when the tray still held a reference to a closed popup.
"""

import json
import os
import subprocess
import sys
from datetime import datetime

from PyQt5.QtCore import QEvent, Qt, QTimer, QRectF, QPointF
from PyQt5.QtGui import QColor, QCursor, QIcon, QPainter, QPixmap, QPen
from PyQt5.QtWidgets import (
    QAction,
    QApplication,
    QDialog,
    QDialogButtonBox,
    QFrame,
    QHBoxLayout,
    QLabel,
    QMenu,
    QPlainTextEdit,
    QPushButton,
    QStyle,
    QSystemTrayIcon,
    QTabWidget,
    QToolButton,
    QVBoxLayout,
    QWidget,
    QWidgetAction,
)

STATUS_DIR = "/hdd/backup-staging/status"
NAMES = ("conspectus", "dotfiles", "stage")
SCRIPTS = {
    "conspectus": "/home/rad1an/dotfiles/scripts/backup-conspectus.sh",
    "dotfiles": "/home/rad1an/dotfiles/scripts/backup-dotfiles.sh",
    "stage": "/home/rad1an/dotfiles/scripts/backup-stage.sh",
}
RUNNER = "/home/rad1an/dotfiles/scripts/run-backup.sh"
ARCHIVE = "/hdd/drive/Backups/backup.zip"
UNLOCK_DIR = "/tmp/opencode/backup-unlock"
MODE = os.environ.get("BACKUP_POPUP_MODE", "popup")

BADGE_COLORS = {"ok": "#2e9e5b", "error": "#d23f3f", "warn": "#888888"}
DOC_LINE = QColor("#ffffff")
DOC_PEN_W = 1.0


def _render_icon(level, scale):
    pix = QPixmap(32 * scale, 32 * scale)
    pix.setDevicePixelRatio(scale)
    pix.fill(QColor(0, 0, 0, 0))       # everything default-transparent

    p = QPainter(pix)
    p.setRenderHint(QPainter.Antialiasing, True)
    p.scale(scale, scale)

    # --- document: hollow white outline ---------------------------------
    doc = QRectF(2.5, 2.5, 25, 20)     # .5 offsets -> crisp 1 px at 1x
    p.setBrush(Qt.NoBrush)             # interior stays transparent
    p.setPen(QPen(DOC_LINE, DOC_PEN_W, Qt.SolidLine,
                  Qt.FlatCap, Qt.RoundJoin))
    p.drawRoundedRect(doc, 3, 3)

    # --- text lines: also white strokes ---------------------------------
    p.setPen(QPen(DOC_LINE, DOC_PEN_W, Qt.SolidLine,
                  Qt.RoundCap, Qt.RoundJoin))
    p.drawLine(QPointF(6.5, 7.5),  QPointF(23.5, 7.5))
    p.drawLine(QPointF(6.5, 11.5), QPointF(16.5, 11.5))
    p.drawLine(QPointF(6.5, 15.5), QPointF(10.5, 15.5))

    # --- transparent halo so the badge detaches from the outline --------
    p.setCompositionMode(QPainter.CompositionMode_Clear)
    p.setPen(QPen(Qt.black, 2))
    p.setBrush(Qt.NoBrush)
    p.drawEllipse(QRectF(11.5, 11.5, 21, 21))
    p.setCompositionMode(QPainter.CompositionMode_SourceOver)

    # --- status badge ---------------------------------------------------
    p.setPen(Qt.NoPen)
    p.setBrush(QColor(BADGE_COLORS.get(level, BADGE_COLORS["warn"])))
    p.drawEllipse(13, 13, 18, 18)      # centre (22, 22), r = 9

    # --- glyph (centred on 22, 22) --------------------------------------
    p.setPen(QPen(QColor("#ffffff"), 2, Qt.SolidLine,
                  Qt.RoundCap, Qt.RoundJoin))
    if level == "ok":
        p.drawLine(QPointF(18.5, 22.5), QPointF(21.0, 25.0))
        p.drawLine(QPointF(21.0, 25.0), QPointF(26.0, 19.0))
    elif level == "error":
        p.drawLine(QPointF(19.0, 19.0), QPointF(25.0, 25.0))
        p.drawLine(QPointF(25.0, 19.0), QPointF(19.0, 25.0))
    else:
        p.drawLine(QPointF(19.0, 22.0), QPointF(25.0, 22.0))

    p.end()
    return pix


def make_icon(level):
    icon = QIcon()
    for scale in (1, 2, 3):
        icon.addPixmap(_render_icon(level, scale))
    return icon


def read_status():
    result = {}
    for name in NAMES:
        try:
            with open(
                os.path.join(STATUS_DIR, name + ".json"), encoding="utf-8"
            ) as handle:
                result[name] = json.load(handle)
        except (OSError, ValueError):
            result[name] = None
    return result


def short_date(value):
    if not value:
        return "never"
    try:
        return datetime.fromisoformat(value).strftime("%b %d")
    except ValueError:
        return str(value)


def full_date(value):
    if not value:
        return "never"
    try:
        return datetime.fromisoformat(value).strftime("%Y-%m-%d %H:%M")
    except ValueError:
        return str(value)


def summarize(data):
    worst = "ok"
    newest = None
    for name in NAMES:
        item = data.get(name)
        if not item:
            continue
        run = item.get("last_run")
        if run and (newest is None or run > newest):
            newest = run
        status = item.get("status")
        if status == "error":
            worst = "error"
        elif status != "ok" and worst == "ok":
            worst = "warn"
    return worst, newest


class Popup(QWidget):
    def __init__(self, app, controller):
        super().__init__()
        self.controller = controller
        flags = {
            "bypass": Qt.Popup | Qt.FramelessWindowHint | Qt.BypassWindowManagerHint,
            "splash": Qt.SplashScreen | Qt.FramelessWindowHint,
            "tool": Qt.Tool | Qt.FramelessWindowHint,
            "popup": Qt.Popup | Qt.FramelessWindowHint,
        }.get(MODE, Qt.Popup | Qt.FramelessWindowHint | Qt.BypassWindowManagerHint)
        self.setWindowFlags(flags)
        self.setWindowRole("quake")
        with open("/tmp/opencode/tray-popup.log", "a", encoding="utf-8") as log:
            log.write(
                f"{datetime.now().isoformat()} mode={MODE} flags={int(self.windowFlags())} "
                f"role={self.windowRole()} app={QApplication.applicationName()} "
                f"desktop={QApplication.desktopFileName()} platform={QApplication.platformName()}\n"
            )
        self.setStyleSheet("""
            QWidget { background: #252525; color: #ececec; }
            QLabel { padding: 2px 6px; }
            QPushButton { background: transparent; border: 0; text-align: left;
                          padding: 6px 8px; color: #ececec; }
            QPushButton:hover { background: #3a3a3a; }
            QToolButton { background: transparent; border: 0; padding: 2px; }
            QToolButton:hover { background: #3a3a3a; }
        """)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(8, 8, 8, 8)
        layout.setSpacing(2)

        title = QLabel("Backups")
        title.setStyleSheet(
            "font-weight: bold; font-size: 12px; padding: 2px 6px 6px 6px;"
        )
        layout.addWidget(title)

        data = read_status()
        icon = QApplication.style().standardIcon(QStyle.SP_BrowserReload)
        for name in NAMES:
            item = data.get(name)
            status = item.get("status", "never") if item else "never"
            run = full_date(item.get("last_run")) if item else "never"
            row = QFrame()
            row_layout = QHBoxLayout(row)
            row_layout.setContentsMargins(4, 2, 4, 2)
            row_layout.addWidget(QLabel(f"{name}: {status}, {run}"), 1)
            button = QToolButton()
            button.setIcon(icon)
            button.setToolTip(f"Back up {name} now")
            button.clicked.connect(lambda checked=False, n=name: self.run_backup(n))
            row_layout.addWidget(button)
            layout.addWidget(row)

        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        layout.addWidget(line)

        for text, action in (
            ("Update system and server (update -s)", self.controller.run_update),
            ("Unlock backup.zip", self.controller.run_key_open),
            ("Seal backup.zip", self.controller.run_key_seal),
            ("Open staging folder", self.controller.open_folder),
            ("Quit", self.controller.app.quit),
        ):
            button = QPushButton(text)
            button.clicked.connect(
                lambda checked=False, fn=action: (fn(), self.close())
            )
            layout.addWidget(button)

        hint = QLabel(f"backup.zip: {ARCHIVE}\nunlocks to: {UNLOCK_DIR}\nmode: {MODE}")
        hint.setStyleSheet("color: #a9a9a9; font-size: 10px; padding: 6px 8px 2px 8px;")
        layout.addWidget(hint)

        self.move(QCursor.pos())

    def run_backup(self, name):
        self.controller.run_backup(name)
        self.close()


def read_log(name):
    path = os.path.join(STATUS_DIR, name + ".log")
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            text = handle.read()
        return text[-100_000:] if len(text) > 100_000 else text
    except OSError as error:
        return f"No log available: {error}\nExpected at {path}\n"


class LogWindow(QDialog):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Backup logs")
        self.resize(900, 600)
        layout = QVBoxLayout(self)
        tabs = QTabWidget()
        for name in NAMES:
            view = QPlainTextEdit()
            view.setReadOnly(True)
            view.setLineWrapMode(QPlainTextEdit.NoWrap)
            view.setPlainText(read_log(name))
            view.setStyleSheet("font-family: monospace; font-size: 11px;")
            tabs.addTab(view, name)
        layout.addWidget(tabs)
        buttons = QDialogButtonBox(QDialogButtonBox.Close)
        buttons.rejected.connect(self.close)
        layout.addWidget(buttons)


def standard_icon(name):
    return QApplication.style().standardIcon(name)


def make_menu(controller):
    """One styled menu used for right-click; left-click does nothing."""
    menu = QMenu()
    menu.setStyleSheet("""
        QMenu { background: #252525; color: #ededed; padding: 6px 3px;
                border: 1px solid #3a3a3a; }
        QMenu::item { padding: 7px 26px 7px 30px; margin: 1px 4px;
                      border-radius: 4px; }
        QMenu::item:selected { background: #3d6a8f; }
        QMenu::separator { height: 1px; background: #3a3a3a;
                           margin: 5px 12px; }
        QMenu::icon { padding-left: 8px; }
    """)

    data = read_status()
    worst, newest = summarize(data)
    status_icon = standard_icon(
        QStyle.SP_DialogApplyButton if worst == "ok" else QStyle.SP_MessageBoxWarning
    )
    not_run = sum(1 for name in NAMES if not data.get(name))
    label = f"Backups: {worst} - {short_date(newest)}"
    if not_run:
        label += f" ({not_run} not run)"
    header = QAction(status_icon, label, menu)
    header.setToolTip("Open the latest logs for each backup")
    header.triggered.connect(controller.show_logs)
    menu.addAction(header)

    reload_icon = standard_icon(QStyle.SP_BrowserReload)
    for name in NAMES:
        item = data.get(name)
        state = item.get("status", "never") if item else "never"
        run = full_date(item.get("last_run")) if item else "never"
        action = QAction(reload_icon, f"{name}: {state} - {run}", menu)
        action.triggered.connect(lambda checked=False, n=name: controller.run_backup(n))
        menu.addAction(action)

    menu.addSeparator()
    for text, icon_name, fn in (
        ("Unlock backup.zip", QStyle.SP_DialogOpenButton, controller.run_key_open),
        ("Seal backup.zip", QStyle.SP_DialogSaveButton, controller.run_key_seal),
    ):
        action = QAction(standard_icon(icon_name), text, menu)
        action.triggered.connect(fn)
        menu.addAction(action)

    menu.addSeparator()
    for text, icon_name, fn in (
        ("Open staging directory", QStyle.SP_DirOpenIcon, controller.open_folder),
        ("Update system and server", QStyle.SP_ArrowUp, controller.run_update),
        ("Quit", QStyle.SP_DialogCloseButton, controller.app.quit),
    ):
        action = QAction(standard_icon(icon_name), text, menu)
        action.triggered.connect(fn)
        menu.addAction(action)
    return menu


class Tray:
    def __init__(self, app):
        self.app = app
        self.last_errors = {}
        self.popup = None
        self.log_window = None
        self.icon = QSystemTrayIcon(make_icon("warn"), app)
        self.icon.activated.connect(self.on_activate)
        self.menu = make_menu(self)
        self.icon.setContextMenu(self.menu)
        self.icon.show()
        self.timer = QTimer(app)
        self.timer.timeout.connect(self.refresh)
        self.timer.start(60_000)
        self.refresh()

    def refresh(self):
        data = read_status()
        worst, newest = summarize(data)
        self.icon.setIcon(make_icon(worst))
        self.icon.setToolTip(short_date(newest))
        for name in NAMES:
            item = data.get(name)
            if not item or item.get("status") != "error":
                self.last_errors[name] = None
                continue
            run = item.get("last_run")
            if self.last_errors.get(name) != run:
                self.icon.showMessage(
                    f"Backup {name} failed",
                    item.get("message", ""),
                    QSystemTrayIcon.Critical,
                    8000,
                )
            self.last_errors[name] = run

    def on_activate(self, reason):
        with open("/tmp/opencode/tray-click.log", "a", encoding="utf-8") as log:
            log.write(
                f"{datetime.now().isoformat()} activation {reason} (left-click ignored)\n"
            )

    def log_geometry(self, position):
        with open("/tmp/opencode/tray-popup.log", "a", encoding="utf-8") as log:
            log.write(
                f"{datetime.now().isoformat()} cursor=({position.x()},{position.y()}) "
                f"window=({self.popup.x()},{self.popup.y()}) "
                f"frame=({self.popup.frameGeometry().x()},{self.popup.frameGeometry().y()})\n"
            )

    def run_backup(self, name):
        subprocess.Popen([RUNNER, name, SCRIPTS[name]])

    def run_update(self):
        subprocess.Popen(
            [
                "alacritty",
                "-e",
                "zsh",
                "-c",
                "source /home/rad1an/dotfiles/config/zsh/aliases.zsh; update -s",
            ]
        )

    def run_key_open(self):
        subprocess.Popen(
            [
                "/usr/bin/python3",
                "/home/rad1an/dotfiles/scripts/backup-key.py",
                "open",
            ]
        )

    def run_key_seal(self):
        subprocess.Popen(
            [
                "/usr/bin/python3",
                "/home/rad1an/dotfiles/scripts/backup-key.py",
                "seal",
            ]
        )

    def open_folder(self):
        subprocess.Popen(["xdg-open", "/hdd/backup-staging"])

    def show_logs(self):
        if self.log_window is None or not self.log_window.isVisible():
            self.log_window = LogWindow()
            self.log_window.show()
        else:
            self.log_window.raise_()
            self.log_window.activateWindow()


if __name__ == "__main__":
    application = QApplication(sys.argv)
    # Krohnkite floats this class (floatingClass in kwinrc), so the popup is
    # kept on top instead of being tiled.
    application.setApplicationName("plasmashell")
    application.setDesktopFileName("plasmashell")
    application.setQuitOnLastWindowClosed(False)
    tray = Tray(application)
    sys.exit(application.exec_())
