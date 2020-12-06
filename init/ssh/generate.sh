#!/usr/bin/env bash

TMP_BASE_DIR=/tmp/ssh-udf

echo "Creating temporary output folders"
mkdir -p ${TMP_BASE_DIR}/jumphost
mkdir -p ${TMP_BASE_DIR}/master
mkdir -p ${TMP_BASE_DIR}/node1
mkdir -p ${TMP_BASE_DIR}/node2
mkdir -p ${TMP_BASE_DIR}/node3
mkdir -p ${TMP_BASE_DIR}/node4

echo "Generating ssh key pairs"
ssh-keygen -b 2048 -t rsa -f ${TMP_BASE_DIR}/jumphost/id_rsa -C ubuntu@jumphost  -q -N ""
ssh-keygen -b 2048 -t rsa -f ${TMP_BASE_DIR}/master/id_rsa   -C ubuntu@master  -q -N ""
ssh-keygen -b 2048 -t rsa -f ${TMP_BASE_DIR}/node1/id_rsa    -C ubuntu@node1  -q -N ""
ssh-keygen -b 2048 -t rsa -f ${TMP_BASE_DIR}/node2/id_rsa    -C ubuntu@node2  -q -N ""
ssh-keygen -b 2048 -t rsa -f ${TMP_BASE_DIR}/node3/id_rsa    -C ubuntu@node3  -q -N ""
ssh-keygen -b 2048 -t rsa -f ${TMP_BASE_DIR}/node4/id_rsa    -C ubuntu@node4  -q -N ""

echo "Moving ssh keypairs to repo"
mv ${TMP_BASE_DIR}/* .
