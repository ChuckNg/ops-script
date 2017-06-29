#!/bin/bash
#Author: Chuck Ng
#Date:   2017-06-16
#Email:  554574099@qq.com 

OPENSSL_BIN=`whereis openssl | awk -F ' ' '{print $2}'`
SSL_FILE_DIR="./ssl"
NUMBITS=1024
#5 yrs
EXPIRE=1825
#req info
CN="CN"
PN="Shanghai"
LN="Shanghai"
ON=""
OU=""
COMMON_NAME=""
SRV_COMMON_NAME=$HOSTNAME
CLI_COMMON_NAME=""
EMAIL=""

if [ -z $OPENSSL_BIN ];then
    echo "No such file $OPENSSL_BIN"
    exit 1
fi

if [ ! -d $SSL_FILE_DIR ];then
    mkdir -p $SSL_FILE_DIR
fi

#CA related
function ca_create(){
    CA_PEM=$SSL_FILE_DIR/ca.pem
    CA_REQ=$SSL_FILE_DIR/ca.csr
    CA_CRT=$SSL_FILE_DIR/ca.crt
    $OPENSSL_BIN genrsa -out $CA_PEM $NUMBITS
    [[ -f $CA_PEM ]] &&\
    $OPENSSL_BIN req -new -key $CA_PEM -out $CA_REQ << EOF
$CN
$PN
$LN
$ON
$OU
$COMMON_NAME
$EMAIL


EOF
    [[ -f $CA_REQ ]] &&\
    $OPENSSL_BIN x509 -req -in $CA_REQ -signkey $CA_PEM -days $EXPIRE -out $CA_CRT
    [[ $? -eq 0 ]] && return 0 || return 1
}

#Server key related
function server_key_create(){
    SRV_PEM=$SSL_FILE_DIR/server.pem
    SRV_REQ=$SSL_FILE_DIR/server.csr
    SRV_CRT=$SSL_FILE_DIR/server.crt
    $OPENSSL_BIN genrsa -out $SRV_PEM $NUMBITS
    [[ -f $SRV_PEM ]] &&\
    $OPENSSL_BIN req -new -key $SRV_PEM -out $SRV_REQ << EOF
$CN
$PN
$LN
$ON
$OU
$SRV_COMMON_NAME
$EMAIL


EOF
    if [[ -f $SRV_REQ ]] && [[ -f "./ssl/ca.crt" ]];then
        $OPENSSL_BIN x509 -req -in $SRV_REQ -signkey $SRV_PEM -CAkey $CA_CRT -CAcreateserial -days $EXPIRE -out $SRV_CRT
    else
        echo "\nLack Cert File"
        return 1
    fi
    
}

#Client key related
function client_key_create(){
    CLI_PEM=$SSL_FILE_DIR/client.pem
    CLI_REQ=$SSL_FILE_DIR/client.csr
    CLI_CRT=$SSL_FILE_DIR/client.crt
    $OPENSSL_BIN genrsa -out $CLI_PEM $NUMBITS
    [[ -f $CLI_PEM ]] &&\
    $OPENSSL_BIN req -new -key $CLI_PEM -out $CLI_REQ << EOF
$CN
$PN
$LN
$ON
$OU
$CLI_COMMON_NAME
$EMAIL


EOF
    if [[ -f $CLI_REQ ]] && [[ -f "./ssl/ca.crt" ]];then
        $OPENSSL_BIN x509 -req -in $CLI_REQ -signkey $CLI_PEM -CAkey $CA_CRT -CAcreateserial -days $EXPIRE -out $CLI_CRT
    else
        echo "\nLack Cert File"
        return 1
    fi
}

function main(){
case $1 in
    ca)
        echo "Create your own CA-file..."
        ca_create
        [[ $? -eq 1 ]] && echo "FAILED!"
    ;;
    server)
        echo "Create your own Server side SSL related-file..."
        server_key_create
        [[ $? -eq 1 ]] && echo "FAILED!"
    ;;
    client)
        echo "Create your own Client side SSL related-file..."
        client_key_create
        [[ $? -eq 1 ]] && echo "FAILED!"
    ;;
    all)
        echo "Create your own CA-file..."
        ca_create
        echo "\nCreate your own Server side SSL related-file..."
        server_key_create
        echo "\nCreate your own Client side SSL related-file..."
        client_key_create
        [[ $? -eq 1 ]] && echo "FAILED!"
    ;;
    *)
        echo "Option Invalid, should be: ca|server|client|all"
    ;;
esac
}

main $1
