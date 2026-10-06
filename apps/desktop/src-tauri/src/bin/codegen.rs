fn main() {
    let target = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../frontend/src/core/desktop.generated.ts");
    std::fs::write(target, mooze_desktop::dto::generated_types()).unwrap();
}
