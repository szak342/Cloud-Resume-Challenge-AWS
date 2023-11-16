#!/bin/bash
# Script for building lambda package, invoked from main.tf
function build() {
    (cd sam-app/ && sam build)
}
build

