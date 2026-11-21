#!/usr/bin/env python3
"""Shamir 2-of-3 wrapper for backup.zip.

No key or share is ever written to disk. setup splits a key into three shares;
open and seal accept any two shares and pass the reconstructed key straight to
7z, so there is no manual combine-and-copy step.

  backup-key.py setup
  backup-key.py open   [archive] [outdir]
  backup-key.py seal   [source]  [archive]
"""

import binascii
import getpass
import os
import subprocess
import sys
import tempfile

ARCHIVE = "/hdd/drive/Backups/backup.zip"
OUTDIR = "/tmp/opencode/backup-unlock"
N = 3
K = 2

EXP = [0] * 512
LOG = [0] * 256


def _mul2(value):
    return ((value << 1) ^ 0x11B) if (value & 0x80) else (value << 1)


_x = 1
for _i in range(255):
    EXP[_i] = _x
    LOG[_x] = _i
    _x ^= _mul2(_x)  # multiply by generator 3; 2 has order 51 in this field
for _i in range(255, 512):
    EXP[_i] = EXP[_i - 255]


def mul(a, b):
    if a == 0 or b == 0:
        return 0
    return EXP[LOG[a] + LOG[b]]


def div(a, b):
    if b == 0:
        raise ZeroDivisionError
    return EXP[(LOG[a] - LOG[b]) % 255]


def split(secret):
    shares = [bytearray() for _ in range(N)]
    for byte in secret:
        coefficient = int.from_bytes(os.urandom(1), "big")
        for index in range(N):
            x = index + 1
            shares[index].append(byte ^ mul(coefficient, x))
    return [binascii.hexlify(bytes(s)).decode("ascii") for s in shares]


def combine(parts):
    out = bytearray()
    length = len(parts[0][1])
    for pos in range(length):
        value = 0
        for i, (xi, yi) in enumerate(parts):
            term = yi[pos]
            for j, (xj, _) in enumerate(parts):
                if i == j:
                    continue
                term = mul(term, div(xj, xi ^ xj))
            value ^= term
        out.append(value)
    return bytes(out)


def decode_share(text):
    text = text.strip().replace(" ", "")
    if ":" in text:
        label, text = text.split(":", 1)
        try:
            x = int(label.strip().rstrip(".)").lstrip("sS"))
        except ValueError:
            x = 0
    else:
        x = 0
    data = binascii.unhexlify(text)
    return x, data


def ask(prompt, password=True):
    if sys.stdin.isatty():
        return getpass.getpass(prompt) if password else input(prompt)
    from PyQt5.QtWidgets import QApplication, QInputDialog, QLineEdit
    app = QApplication.instance() or QApplication(sys.argv)
    text, ok = QInputDialog.getText(
        None, "Backup key", prompt,
        QLineEdit.Password if password else QLineEdit.Normal,
    )
    if not ok:
        raise KeyboardInterrupt
    return text


def get_two_shares():
    parts = []
    for n in (1, 2):
        raw = ask(f"Share {n} (hex, any order): ")
        x, data = decode_share(raw)
        if x < 1 or x > N:
            raise ValueError("share needs a label 1, 2 or 3, for example '2:abcdef'")
        parts.append((x, data))
    if parts[0][0] == parts[1][0]:
        raise ValueError("the two shares must be different")
    return combine(parts)


def run_7z(args):
    result = subprocess.run(["7z"] + args, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stdout[-2000:], file=sys.stderr)
        print(result.stderr[-2000:], file=sys.stderr)
        raise SystemExit(result.returncode)
    return result.stdout


def open_with_o(path):
    """Same effect as the shell's o() function: detached xdg-open."""
    subprocess.Popen(
        ["xdg-open", path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def do_setup():
    key = ask("Final backup.zip key: ")
    if not key:
        raise SystemExit("empty key")
    for index, share in enumerate(split(key.encode()), 1):
        print(f"Share {index}: {index}:{share}")
    print("Record three shares. Any two restore the key. Nothing was stored.")


def do_open(archive, outdir):
    key = get_two_shares().decode("utf-8")
    os.makedirs(outdir, exist_ok=True)
    print("Extracting", archive)
    print(run_7z(["x", "-y", f"-p{key}", f"-o{outdir}", archive])[-800:])
    for name in os.listdir(outdir):
        path = os.path.join(outdir, name)
        if not os.path.isfile(path):
            continue
        target = os.path.join(outdir, "extracted-" + name)
        os.makedirs(target, exist_ok=True)
        listing = subprocess.run(
            ["7z", "l", f"-p{key}", path], capture_output=True, text=True
        )
        if listing.returncode == 0 and "Type =" in listing.stdout:
            try:
                run_7z(["x", "-y", f"-p{key}", f"-o{target}", path])
                print("Nested archive extracted to", target)
            except SystemExit:
                print("Not a nested archive:", path)
    print("Output:", outdir)
    open_with_o(outdir)


def do_seal(source, archive):
    key = get_two_shares().decode("utf-8")
    if not source and not sys.stdin.isatty():
        from PyQt5.QtWidgets import QApplication, QFileDialog
        app = QApplication.instance() or QApplication(sys.argv)
        source, _ = QFileDialog.getExistingDirectory(None, "Folder to seal")
    if not source or not os.path.exists(source):
        raise SystemExit(f"source missing: {source}")
    print(run_7z(["a", "-y", f"-p{key}", "-mem=AES256", archive, source])[-800:])
    print("Sealed", archive)


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "setup"
    if mode == "setup":
        do_setup()
    elif mode == "open":
        do_open(sys.argv[2] if len(sys.argv) > 2 else ARCHIVE,
                sys.argv[3] if len(sys.argv) > 3 else OUTDIR)
    elif mode == "seal":
        do_seal(sys.argv[2] if len(sys.argv) > 2 else "",
                sys.argv[3] if len(sys.argv) > 3 else ARCHIVE)
    else:
        raise SystemExit("usage: backup-key.py setup|open|seal")
