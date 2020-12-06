#!/usr/bin/env bash

echo "Build all images from source with debug tools"
make DEBUG=true build

echo "Push all images with debug tools to repository"
make DEBUG=true push
