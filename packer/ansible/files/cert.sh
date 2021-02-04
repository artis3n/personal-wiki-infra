#!/usr/bin/env bash

sudo certbot run -a manual -i nginx -d wiki.artis3nal.com --preferred-challenges dns
