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
wasi-virt adapted.wasm \
	--allow-clocks \
  --allow-env \
  --allow-exit \
  --allow-random \
  --stdin=allow --stdout=allow --stderr=allow \
	--mount /usr=guest/target/wasm32-wasi/wasi-deps/usr/ \
	-o virtualized.wasm
cargo run -p host