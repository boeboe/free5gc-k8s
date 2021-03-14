#!/usr/bin/env bash

echo "Build gnbsim image from source without debug tools and push to repository"
make DEBUG=false build-gnbsim push-gnbsim

echo "Build gnbsim image from source with debug tools and push to repository"
make DEBUG=true build-gnbsim push-gnbsim
