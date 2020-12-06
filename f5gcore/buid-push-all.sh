#!/usr/bin/env bash

echo "Build all images from source without debug tools"
make DEBUG=false build

echo "Push all images without debug tools to repository"
make DEBUG=false push
