#!/bin/env bash
set -e

if [ ! -f wasi_snapshot_preview1.reactor.wasm ]
then
	curl https://github.com/bytecodealliance/wasmtime/releases/download/v13.0.0/wasi_snapshot_preview1.reactor.wasm -L -o wasi_snapshot_preview1.reactor.wasm
fi

cargo build --target wasm32-wasi -p guest
wasm-tools component new --adapt wasi_snapshot_preview1=wasi_snapshot_preview1.reactor.wasm \
	target/wasm32-wasi/debug/guest.wasm \
	-o adapted.wasm
mkdir -p wasi-root
cp -rv guest/target/wasm32-wasi/wasi-deps/usr wasi-root/
pip install python-ulid --prefix wasi-root/usr/local
wasi-virt adapted.wasm \
	--allow-clocks \
  --allow-env \
  --allow-exit \
  --allow-random \
  --stdin=allow --stdout=allow --stderr=allow \
  -e PYTHONHOME=/usr/local \
  -e PYTHONPATH=/usr/local/lib/python3.11:/usr/local/lib/python3.11/site-packages \
	--mount /=wasi-root/ \
	-o virtualized.wasm
cargo run -p host --release
