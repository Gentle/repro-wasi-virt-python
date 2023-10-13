wit_bindgen::generate!({
    path: "../wit",
    world: "repro",
    exports: {
        world: Repro,
    }
});

pub struct Repro;
impl Guest for Repro {
    fn version() -> wit_bindgen::rt::string::String {
        _ = dbg!(std::env::current_dir());
        pyo3::prepare_freethreaded_python();
        pyo3::Python::with_gil(|py| py.version().to_string())
    }
}
