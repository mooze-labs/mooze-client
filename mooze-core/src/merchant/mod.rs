//! Merchant (point of sale) mode.
//!
//! Port of the data and domain layers of `lib/features/merchant/**` and
//! `lib/utils/store_mode.dart`: products, cart math, keypad entry,
//! sale validation and mode flags.

pub mod cart;
pub mod mode;
pub mod product;

pub use cart::{
    can_finish_sale, validate_sale, Cart, CartItem, KeypadValue, MerchantValidation, MerchantValidationError,
    SaleLimits, MIN_SALE_BRL,
};
pub use mode::MerchantModeStore;
pub use product::{Product, ProductStore};
