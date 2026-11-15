#!/usr/bin/env python3
"""Exit as soon as no Ctrl key is held on any keyboard. Needs read access to /dev/input (group `input`)."""
import fcntl
import os
import sys
import time

EVIOCGKEY = 0x80604518  # 96 bytes of key bits
CTRL_KEYS = (29, 97)  # KEY_LEFTCTRL, KEY_RIGHTCTRL

def keyboard_nodes():
    """Event nodes whose key bitmap has a Ctrl key. Opening and closing a device costs ~15 ms, so skip the rest."""
    nodes = []
    with open("/proc/bus/input/devices") as f:
        blocks = f.read().split("\n\n")
    for block in blocks:
        node = keys = None
        for line in block.splitlines():
            if line.startswith("H: Handlers="):
                node = next((w for w in line.split() if w.startswith("event")), None)
            elif line.startswith("B: KEY="):
                words = line[len("B: KEY="):].split()
                keys = sum(int(w, 16) << (64 * i) for i, w in enumerate(reversed(words)))
        if node and keys and any(keys >> k & 1 for k in CTRL_KEYS):
            nodes.append("/dev/input/" + node)
    return nodes


fds = []
for path in keyboard_nodes():
    try:
        fds.append(os.open(path, os.O_RDONLY | os.O_NONBLOCK))
    except OSError:
        pass
if not fds:
    sys.exit(2)


def ctrl_held():
    for fd in fds:
        buf = bytearray(96)
        try:
            fcntl.ioctl(fd, EVIOCGKEY, buf)
        except OSError:
            continue
        if any(buf[k // 8] >> (k % 8) & 1 for k in CTRL_KEYS):
            return True
    return False


deadline = time.time() + 120
while ctrl_held() and time.time() < deadline:
    time.sleep(0.015)
