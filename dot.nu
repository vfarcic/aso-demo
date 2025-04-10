#!/usr/bin/env nu

source  scripts/common.nu
source  scripts/kubernetes.nu
source  scripts/cert-manager.nu
source  scripts/aso.nu
source  scripts/crossplane.nu

def main [] {}

def "main setup" [] {

    rm --force .env

    main create kubernetes kind

    main apply certmanager

    kubectl create namespace a-team

    main apply aso --namespace a-team --sync_period "1m"

    let name = $"my-db-(date now | format date "%Y%m%d%H%M%S")"

    open db/password.yaml
        | upsert metadata.name $"($name)-password"
        | save db/password.yaml --force

    open db/resource-group.yaml
        | upsert metadata.name $name
        | save db/resource-group.yaml --force

    open db/server.yaml
        | upsert metadata.name $name
        | upsert spec.owner.name $name
        | upsert spec.administratorLoginPassword.name $"($name)-password"
        | upsert spec.operatorSpec.secretExpressions.0.name $name
        | upsert spec.operatorSpec.secretExpressions.1.name $name
        | upsert spec.operatorSpec.secretExpressions.2.name $name
        | save db/server.yaml --force

    open db/server-2.yaml
        | upsert metadata.name $"($name)-2"
        | upsert spec.administratorLoginPassword.name $"($name)-password"
        | save db/server-2.yaml --force

    open db/firewall-rule.yaml
        | upsert metadata.name $name
        | upsert spec.owner.name $name
        | upsert spec.azureName $name
        | save db/firewall-rule.yaml --force

    $"export RESOURCE_NAME=($name)\n" | save --append .env

    main apply crossplane --db true --preview true

    let dot_name = $"my-db-(date now | format date "%Y%m%d%H%M%S")"

    open dot-sql.yaml
        | upsert metadata.name $dot_name
        | save dot-sql.yaml --force

    open dot-sql-password.yaml
        | upsert metadata.name $"($dot_name)-password"
        | save dot-sql-password.yaml --force

    (
        kubectl --namespace a-team apply
            --filename dot-sql-password.yaml
    )

    $"export DOT_RESOURCE_NAME=($dot_name)\n" | save --append .env

    main print source
    
}

def "main destroy" [] {

    main destroy kubernetes kind

}
