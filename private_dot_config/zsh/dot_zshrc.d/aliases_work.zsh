#!/usr/bin/env zsh

# dbt aliases:
alias deferdbtrun='dbt run --defer --state=$DBT_MANIFEST_PATH'
alias deferdbttest='dbt test --defer --state=$DBT_MANIFEST_PATH'

# planet vpn aliases
alias stop_vpn="sudo ip link set planet down"
alias start_vpn="sudo ip link set planet up"
alias restart_vpn="stop_vpn && start_vpn"
