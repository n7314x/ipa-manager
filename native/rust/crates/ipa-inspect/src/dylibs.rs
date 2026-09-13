#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LinkedDylib {
    pub install_name: String,
    pub weak: bool,
}
