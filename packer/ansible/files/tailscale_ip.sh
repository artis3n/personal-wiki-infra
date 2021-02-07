#!/bin/bash

tailscale netcheck | grep IPv4 | awk '{ print $4 }' | cut -d ':' -f1
