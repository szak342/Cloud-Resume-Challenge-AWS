#!/bin/bash
function build() {
    (cd ../"$1"/ && sam build)
}

build "$1"

