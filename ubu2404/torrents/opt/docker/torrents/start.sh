#!/bin/bash
mount /mnt/storage
[ -d /mnt/storage/Downloads/transmission/ ] docker compose up -d
