//! Merchant products and their store.
//!
//! Port of `ProductEntity`, the product use cases and `ProductDriftDataSource`
//! (`lib/features/merchant/**`). Prices are BRL `f64`, as in Dart.

use serde::{Deserialize, Serialize};

use crate::ports::KvStore;
use crate::store::json::{bump_seq, delete_key, get_json, id_key, list_json, next_id, put_json};
use crate::{Error, Result};

/// Validation code: empty name.
pub const PRODUCT_NAME_EMPTY: &str = "product.name_empty";
/// Validation code: price not above zero.
pub const PRODUCT_PRICE_INVALID: &str = "product.price_invalid";

const ROWS: &str = "db/products/row/";
const SEQ: &str = "db/products/seq";

/// One product.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Product {
    /// `None` for a product not yet saved.
    pub id: Option<i64>,
    pub name: String,
    /// Price in BRL.
    pub price: f64,
    pub created_at_ms: u64,
}

impl Product {
    /// Unsaved product.
    pub fn new(name: impl Into<String>, price: f64, created_at_ms: u64) -> Self {
        Self { id: None, name: name.into(), price, created_at_ms }
    }

    /// True if the name is not empty and the price is above zero.
    pub fn is_valid(&self) -> bool {
        self.validate().is_none()
    }

    /// Stable error code, or `None` when valid.
    pub fn validate(&self) -> Option<&'static str> {
        if self.name.is_empty() {
            return Some(PRODUCT_NAME_EMPTY);
        }
        // NOTE(port): NaN passes `price <= 0` in Dart too.
        if self.price <= 0.0 {
            return Some(PRODUCT_PRICE_INVALID);
        }
        None
    }
}

/// Product persistence with the use-case validation rules.
#[derive(Debug, Clone)]
pub struct ProductStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> ProductStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    fn check_name_len(name: &str) -> Result<()> {
        // Drift column limit: 1..=255 characters.
        if name.chars().count() > 255 {
            return Err(Error::invalid("product name longer than 255"));
        }
        Ok(())
    }

    /// Validates and inserts a product. Returns the new id. Any `id` on input is ignored.
    pub async fn create(&self, product: &Product) -> Result<i64> {
        if let Some(code) = product.validate() {
            return Err(Error::invalid(code));
        }
        Self::check_name_len(&product.name)?;
        let id = next_id(&self.kv, SEQ).await?;
        let row = Product { id: Some(id), ..product.clone() };
        put_json(&self.kv, &id_key(ROWS, id), &row).await?;
        Ok(id)
    }

    /// Writes an existing product with its original id, for a data
    /// migration. Skips validation: old rows stay readable even if they
    /// break today's rules. Replaces a product with the same id.
    pub async fn import(&self, product: &Product) -> Result<()> {
        let id = product.id.filter(|id| *id > 0).ok_or_else(|| Error::invalid("imported product needs a positive id"))?;
        put_json(&self.kv, &id_key(ROWS, id), product).await?;
        bump_seq(&self.kv, SEQ, id).await
    }

    /// Every product in id order (drift select without `ORDER BY`).
    pub async fn get_all(&self) -> Result<Vec<Product>> {
        Ok(list_json(&self.kv, ROWS).await?.into_iter().map(|(_, p)| p).collect())
    }

    /// One product, or `None`.
    pub async fn get_by_id(&self, id: i64) -> Result<Option<Product>> {
        get_json(&self.kv, &id_key(ROWS, id)).await
    }

    /// Validates and replaces a product. Returns false if no row has that id.
    pub async fn update(&self, product: &Product) -> Result<bool> {
        let Some(id) = product.id else {
            return Err(Error::invalid("Product ID is required for update"));
        };
        if let Some(code) = product.validate() {
            return Err(Error::invalid(code));
        }
        Self::check_name_len(&product.name)?;
        let key = id_key(ROWS, id);
        if self.kv.get(&key).await?.is_none() {
            return Ok(false);
        }
        put_json(&self.kv, &key, product).await?;
        Ok(true)
    }

    /// Deletes a product. Ids must be positive. Returns false if absent.
    pub async fn delete(&self, id: i64) -> Result<bool> {
        if id <= 0 {
            return Err(Error::invalid("Invalid product ID"));
        }
        let key = id_key(ROWS, id);
        let existed = self.kv.get(&key).await?.is_some();
        delete_key(&self.kv, &key).await?;
        Ok(existed)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{block_on, MemoryKv};

    #[test]
    fn validation_codes() {
        assert_eq!(Product::new("", 1.0, 0).validate(), Some(PRODUCT_NAME_EMPTY));
        assert_eq!(Product::new("Café", 0.0, 0).validate(), Some(PRODUCT_PRICE_INVALID));
        assert!(Product::new("Café", 4.5, 0).is_valid());
    }

    #[test]
    fn crud() {
        block_on(async {
            let s = ProductStore::new(MemoryKv::new());
            let a = s.create(&Product::new("Café", 4.5, 1)).await.unwrap();
            let b = s.create(&Product::new("Pão", 1.25, 2)).await.unwrap();
            assert!(s.create(&Product::new("", 1.0, 3)).await.is_err());
            assert_eq!(s.get_all().await.unwrap().iter().map(|p| p.id).collect::<Vec<_>>(), [Some(a), Some(b)]);

            let mut p = s.get_by_id(a).await.unwrap().unwrap();
            p.price = 5.0;
            assert!(s.update(&p).await.unwrap());
            assert_eq!(s.get_by_id(a).await.unwrap().unwrap().price, 5.0);
            assert!(!s.update(&Product { id: Some(99), ..p.clone() }).await.unwrap());
            assert!(s.update(&Product { id: None, ..p }).await.is_err());

            assert!(s.delete(0).await.is_err());
            assert!(s.delete(a).await.unwrap());
            assert!(!s.delete(a).await.unwrap());
            // Ids never repeat after delete.
            assert_eq!(s.create(&Product::new("Bolo", 9.0, 4)).await.unwrap(), b + 1);
        });
    }
}
