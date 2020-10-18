#!/bin/bash

_s=$(dirname -- "$(realpath -- "$0")")
_dex=$_s/dex/dex

xrdb -query | grep -q '^awesome\.started:\s*true$' && exit

xrdb -merge <<< 'awesome.started:true'

$_dex --environment Awesome --autostart --search-paths "$XDG_CONFIG_HOME/autostart"
