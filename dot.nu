#!/usr/bin/env nu

source  scripts/common.nu
source  scripts/kubernetes.nu
source  scripts/cert-manager.nu
source  scripts/aso.nu

def main [] {}

def "main setup" [] {

    rm --force .env

    main create kubernetes kind

    main apply certmanager

    kubectl create namespace a-team

    main apply aso --namespace a-team

    main print source
    
}

def "main destroy" [] {

    main destroy kubernetes kind

}
