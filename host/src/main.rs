use std::fs::File;

use wasi_common::pipe::ReadPipe;
use wasmtime::{
    component::{Component, Instance, InstancePre, Linker},
    Config, Engine, Store,
};
use wasmtime_wasi::preview2::{
    command::add_to_linker, pipe::AsyncReadStream, DirPerms, FilePerms, Table, WasiCtx,
    WasiCtxBuilder, WasiView,
};

wasmtime::component::bindgen!({
    path: "../wit",
    world: "repro",
    async: true
});

pub struct Ctx {
    wasi: WasiCtx,
    table: Table,
}
impl WasiView for Ctx {
    fn table(&self) -> &Table {
        &self.table
    }

    fn table_mut(&mut self) -> &mut Table {
        &mut self.table
    }

    fn ctx(&self) -> &wasmtime_wasi::preview2::WasiCtx {
        &self.wasi
    }

    fn ctx_mut(&mut self) -> &mut wasmtime_wasi::preview2::WasiCtx {
        &mut self.wasi
    }
}

async fn instantiate_component(
    engine: &Engine,
    component: Component,
    preopen: bool,
) -> (Repro, Instance, Store<Ctx>) {
    let mut linker = Linker::new(engine);
    add_to_linker(&mut linker).unwrap();
    let mut table = Table::new();
    let mut builder = WasiCtxBuilder::new();
    builder
        .stdin(
            AsyncReadStream::new(tokio::io::empty()),
            wasmtime_wasi::preview2::IsATTY::No,
        )
        .inherit_stdout()
        .inherit_stderr();
    if preopen {
        builder.preopened_dir(
            wasmtime_wasi::Dir::from_std_file(File::open("./wasi-root/").unwrap()),
            DirPerms::all(),
            FilePerms::all(),
            "/",
        );
    }
    let wasi = builder.build(&mut table).unwrap();
    let mut store = Store::new(&engine, Ctx { wasi, table });
    let (init, instance) = Repro::instantiate_async(&mut store, &component, &linker)
        .await
        .unwrap();
    (init, instance, store)
}

#[tokio::main]
async fn main() {
    let mut config = Config::new();
    config.async_support(true).wasm_component_model(true);
    let engine = Engine::new(&config).unwrap();
    println!("Initializing non-virtualized component with preopened dir");
    let adapted = std::fs::read("adapted.wasm").unwrap();
    let (component, _, mut store) =
        instantiate_component(&engine, Component::new(&engine, adapted).unwrap(), true).await;
    let x = component.call_version(&mut store).await.unwrap();
    println!("Response: {x}");
    println!("Initializing virtualized component without preopened dir");
    let virtualized = std::fs::read("virtualized.wasm").unwrap();
    let (component, _, mut store) = instantiate_component(
        &engine,
        Component::new(&engine, virtualized).unwrap(),
        false,
    )
    .await;
    let x = component.call_version(&mut store).await.unwrap();
}
