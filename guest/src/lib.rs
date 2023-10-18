wit_bindgen::generate!({
    path: "../wit",
    world: "repro",
    exports: {
        world: Repro,
    }
});

pub struct Repro;
impl Guest for Repro {
    fn init() -> wit_bindgen::rt::string::String {
        pyo3::prepare_freethreaded_python();
        pyo3::Python::with_gil(|py| py.version().to_string())
    }
    fn ulid() -> String {
        pyo3::Python::with_gil(|py| {
            let module = py
                .import("ulid")
                .expect("loading module from site-packages");
            let ulid = module
                .getattr("ULID")
                .expect("getting function from module");
            ulid.call0()
                .expect("running the python function")
                .to_string()
        })
    }
}
