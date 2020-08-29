#!/bin/bash

npm_exe='pnpm'
npx_exe='pnpx'

p='svelte-layout-resizable-demo'

$npx_exe degit sveltejs/template "$p"

cd "$p"
$npm_exe install
$npm_exe install -D ../../../../svelte-layout-resizable/
$npm_exe install -D svelte-preprocess node-sass

patch -p1 < ../demo.patch

$npm_exe install -D inliner
npm run build
npm run start &

sleep 4 # wait for webserver to start
npx inliner http://localhost:5000/ > ../demo.html

kill %1 # kill webserver
