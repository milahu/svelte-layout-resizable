#!/bin/bash

npm_exe='pnpm'
npx_exe='pnpx'

p='svelte-layout-resizable-demo'

$npx_exe degit sveltejs/template "$p"

cd "$p"
$npm_exe install
$npm_exe install -D ../../../../svelte-layout-resizable/

patch -p1 < ../demo.patch

$npm_exe install -D inliner
$npm_exe run build
$npm_exe run start &

sleep 4 # wait for webserver to start
$npx_exe --quiet inliner http://localhost:5000/ > ../demo.html

kill %1 # kill webserver
clear
echo done demo.html
