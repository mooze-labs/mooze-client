//! Cart, keypad entry and sale validation.

use serde::{Deserialize, Serialize};

/// Validation code: empty item name.
pub const CART_ITEM_NAME_EMPTY: &str = "cart_item.name_empty";
/// Validation code: price not above zero.
pub const CART_ITEM_PRICE_INVALID: &str = "cart_item.price_invalid";
/// Validation code: quantity not above zero.
pub const CART_ITEM_QUANTITY_INVALID: &str = "cart_item.quantity_invalid";

/// Smallest sale the finish button accepts, in BRL.
pub const MIN_SALE_BRL: f64 = 20.0;
/// Largest keypad value in cents (R$ 9.999,99).
pub const MAX_KEYPAD_CENTS: u64 = 999_999;

/// One cart line.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CartItem {
    pub product_id: i64,
    pub name: String,
    /// Unit price in BRL.
    pub price: f64,
    pub quantity: u32,
}

impl CartItem {
    /// `price * quantity`.
    pub fn total(&self) -> f64 {
        self.price * f64::from(self.quantity)
    }

    /// True when the item passes [`Self::validate`].
    pub fn is_valid(&self) -> bool {
        self.validate().is_none()
    }

    /// Stable error code, or `None` when valid.
    pub fn validate(&self) -> Option<&'static str> {
        if self.name.is_empty() {
            return Some(CART_ITEM_NAME_EMPTY);
        }
        if self.price <= 0.0 {
            return Some(CART_ITEM_PRICE_INVALID);
        }
        if self.quantity == 0 {
            return Some(CART_ITEM_QUANTITY_INVALID);
        }
        None
    }
}

/// Cart keyed by product id. Keeps insertion order.
#[derive(Debug, Clone, PartialEq, Default, Serialize, Deserialize)]
pub struct Cart {
    items: Vec<CartItem>,
}

impl Cart {
    /// Empty cart.
    pub fn new() -> Self {
        Self::default()
    }

    /// Adds one unit. A new product enters with quantity 1.
    pub fn add_item(&mut self, product_id: i64, name: &str, price: f64) {
        match self.items.iter_mut().find(|i| i.product_id == product_id) {
            Some(i) => i.quantity += 1,
            None => self.items.push(CartItem { product_id, name: name.to_owned(), price, quantity: 1 }),
        }
    }

    /// Removes one unit. A line at quantity 1 leaves the cart.
    pub fn remove_item(&mut self, product_id: i64) {
        if let Some(pos) = self.items.iter().position(|i| i.product_id == product_id) {
            if self.items[pos].quantity > 1 {
                self.items[pos].quantity -= 1;
            } else {
                self.items.remove(pos);
            }
        }
    }

    /// Adds when `increment`, else removes.
    pub fn update_quantity(&mut self, product_id: i64, name: &str, price: f64, increment: bool) {
        if increment {
            self.add_item(product_id, name, price);
        } else {
            self.remove_item(product_id);
        }
    }

    /// Adds a loose keypad value as its own line. `now_ms` is the product id.
    /// Values at or below zero are ignored.
    pub fn add_loose_value(&mut self, now_ms: u64, label: &str, value: f64) {
        if value > 0.0 {
            self.add_item(now_ms as i64, label, value);
        }
    }

    /// Sum of line totals in BRL.
    pub fn total(&self) -> f64 {
        self.items.iter().fold(0.0, |s, i| s + i.total())
    }

    /// Empties the cart.
    pub fn clear(&mut self) {
        self.items.clear();
    }

    /// Quantity of one product, 0 if absent.
    pub fn quantity_for(&self, product_id: i64) -> u32 {
        self.items.iter().find(|i| i.product_id == product_id).map_or(0, |i| i.quantity)
    }

    /// Lines in insertion order.
    pub fn items(&self) -> &[CartItem] {
        &self.items
    }

    /// True if empty.
    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }
}

/// Keypad value typed digit by digit, in cents. Display starts at "0.00".
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct KeypadValue {
    cents: u64,
}

impl KeypadValue {
    /// Zero.
    pub fn new() -> Self {
        Self::default()
    }

    /// Appends a digit (0-9). Values above [`MAX_KEYPAD_CENTS`] are rejected.
    pub fn add_digit(&mut self, digit: u8) {
        if digit > 9 {
            return;
        }
        let next = self.cents.saturating_mul(10).saturating_add(u64::from(digit));
        if next > MAX_KEYPAD_CENTS {
            return;
        }
        self.cents = next;
    }

    /// Drops the last digit.
    pub fn delete_digit(&mut self) {
        self.cents /= 10;
    }

    /// Resets to zero.
    pub fn clear(&mut self) {
        self.cents = 0;
    }

    /// Value in cents.
    pub fn cents(&self) -> u64 {
        self.cents
    }

    /// Value in BRL.
    pub fn value(&self) -> f64 {
        self.cents as f64 / 100.0
    }

    /// Display text with two decimals, as `toStringAsFixed(2)`.
    pub fn display(&self) -> String {
        format!("{}.{:02}", self.cents / 100, self.cents % 100)
    }

    /// Moves the typed value into `cart` as a loose line and resets.
    pub fn add_to_cart(&mut self, cart: &mut Cart, now_ms: u64, label: &str) {
        cart.add_loose_value(now_ms, label, self.value());
        self.clear();
    }
}

/// Sale validation error.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum MerchantValidationError {
    None,
    BelowMinimum,
    AboveTransaction,
    AboveRemaining,
    InvalidAmount,
}

/// Sale validation result. `amount` is the limit that was hit.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct MerchantValidation {
    pub error: MerchantValidationError,
    pub amount: Option<f64>,
    pub is_valid: bool,
}

impl MerchantValidation {
    /// Valid result.
    pub fn valid() -> Self {
        Self { error: MerchantValidationError::None, amount: None, is_valid: true }
    }

    fn failure(error: MerchantValidationError, amount: f64) -> Self {
        Self { error, amount: Some(amount), is_valid: false }
    }
}

/// User limits the validation needs (from the user levels API).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct SaleLimits {
    pub absolute_min_limit: f64,
    pub allowed_spending: f64,
}

/// Validates a sale total against the user limits.
///
/// Missing limits (still loading or failed) and non-positive totals are valid.
pub fn validate_sale(total: f64, limits: Option<SaleLimits>) -> MerchantValidation {
    let Some(l) = limits else {
        return MerchantValidation::valid();
    };
    if total <= 0.0 {
        return MerchantValidation::valid();
    }
    if total < l.absolute_min_limit {
        return MerchantValidation::failure(MerchantValidationError::BelowMinimum, l.absolute_min_limit);
    }
    if total > l.allowed_spending {
        return MerchantValidation::failure(MerchantValidationError::AboveTransaction, l.allowed_spending);
    }
    MerchantValidation::valid()
}

/// True if the finish-sale button is enabled. `None` total means no validation.
pub fn can_finish_sale(total: Option<f64>) -> bool {
    total.is_none_or(|t| t >= MIN_SALE_BRL)
}

/// True if the "minimum sale" hint shows (total above zero but under the minimum).
pub fn shows_min_sale_hint(total: Option<f64>) -> bool {
    total.is_some_and(|t| t > 0.0 && t < MIN_SALE_BRL)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cart_add_remove_total_order() {
        let mut c = Cart::new();
        c.add_item(2, "Pão", 1.5);
        c.add_item(1, "Café", 4.0);
        c.add_item(2, "Pão", 1.5);
        assert_eq!(c.quantity_for(2), 2);
        assert_eq!(c.total(), 7.0);
        assert_eq!(c.items().iter().map(|i| i.product_id).collect::<Vec<_>>(), [2, 1]);
        c.update_quantity(2, "Pão", 1.5, false);
        c.remove_item(1);
        c.remove_item(42);
        assert_eq!(c.items().len(), 1);
        assert_eq!(c.quantity_for(1), 0);
        c.clear();
        assert!(c.is_empty());
    }

    #[test]
    fn cart_item_validation() {
        let i = CartItem { product_id: 1, name: "x".into(), price: 2.0, quantity: 3 };
        assert_eq!(i.total(), 6.0);
        assert!(i.is_valid());
        assert_eq!(CartItem { quantity: 0, ..i.clone() }.validate(), Some(CART_ITEM_QUANTITY_INVALID));
        assert_eq!(CartItem { price: 0.0, ..i.clone() }.validate(), Some(CART_ITEM_PRICE_INVALID));
        assert_eq!(CartItem { name: String::new(), ..i }.validate(), Some(CART_ITEM_NAME_EMPTY));
    }

    #[test]
    fn keypad_handlers() {
        let mut k = KeypadValue::new();
        assert_eq!(k.display(), "0.00");
        for d in [1, 2, 3, 4] {
            k.add_digit(d);
        }
        assert_eq!(k.display(), "12.34");
        k.delete_digit();
        assert_eq!(k.display(), "1.23");
        for d in [9, 9, 9, 9] {
            k.add_digit(d);
        }
        assert_eq!(k.display(), "1239.99", "the digit that would pass 9999.99 is rejected");
        k.add_digit(9);
        assert_eq!(k.cents(), 123_999);
        let mut cart = Cart::new();
        k.add_to_cart(&mut cart, 1_700_000_000_000, "Valor avulso");
        assert_eq!(cart.items()[0].product_id, 1_700_000_000_000);
        assert_eq!(cart.total(), 1239.99);
        assert_eq!(k.display(), "0.00");
        k.add_to_cart(&mut cart, 1, "x");
        assert_eq!(cart.items().len(), 1);
    }

    #[test]
    fn sale_rules() {
        let l = Some(SaleLimits { absolute_min_limit: 20.0, allowed_spending: 500.0 });
        assert!(validate_sale(0.0, l).is_valid);
        assert!(validate_sale(10.0, None).is_valid);
        let v = validate_sale(10.0, l);
        assert_eq!((v.error, v.amount), (MerchantValidationError::BelowMinimum, Some(20.0)));
        assert_eq!(validate_sale(600.0, l).error, MerchantValidationError::AboveTransaction);
        assert!(validate_sale(100.0, l).is_valid);
        assert!(can_finish_sale(None));
        assert!(!can_finish_sale(Some(19.99)));
        assert!(can_finish_sale(Some(20.0)));
        assert!(shows_min_sale_hint(Some(5.0)));
        assert!(!shows_min_sale_hint(Some(0.0)));
    }
}
