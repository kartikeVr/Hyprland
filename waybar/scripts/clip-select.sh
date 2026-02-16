#!/bin/sh
cliphist list | hyprlauncher -n --dmenu | cliphist decode | wl-copy
