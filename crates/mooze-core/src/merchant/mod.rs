//! Merchant (point of sale) mode.
//!
//! Products, cart math, keypad entry, sale validation and mode flags.

pub mod cart;
pub mod mode;
pub mod product;

pub use cart::{
    can_finish_sale, validate_sale, Cart, CartItem, KeypadValue, MerchantValidation, MerchantValidationError,
    SaleLimits, MIN_SALE_BRL,
};
pub use mode::MerchantModeStore;
pub use product::{Product, ProductStore};
