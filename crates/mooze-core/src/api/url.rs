//! URL and JSON envelope helpers shared by the API clients.

use serde_json::Value;

/// Joins a base URL and a path the way Dio does.
///
/// Absolute paths (`http:`/`https:`) win. Otherwise Dio concatenates the two
/// strings and collapses `//` after the scheme separator.
pub fn join_url(base: &str, path: &str) -> String {
    if path.starts_with("http:") || path.starts_with("https:") {
        return path.to_owned();
    }
    let url = format!("{base}{path}");
    let parts: Vec<&str> = url.split(":/").collect();
    if parts.len() == 2 {
        format!("{}:/{}", parts[0], parts[1].replace("//", "/"))
    } else {
        url
    }
}

/// Percent-encodes one path segment. Keeps RFC 3986 unreserved characters.
pub fn encode_path_segment(segment: &str) -> String {
    let mut out = String::with_capacity(segment.len());
    for b in segment.bytes() {
        if b.is_ascii_alphanumeric() || matches!(b, b'-' | b'.' | b'_' | b'~') {
            out.push(b as char);
        } else {
            out.push_str(&format!("%{b:02X}"));
        }
    }
    out
}

/// Dart `json['data'] ?? json`: the `data` field if present and not null.
pub fn data_or_self(value: &Value) -> &Value {
    match value.get("data") {
        Some(data) if !data.is_null() => data,
        _ => value,
    }
}

/// Dart `body['data'] is Map ? body['data'] : body`: `data` only if it is an object.
pub fn data_object_or_self(value: &Value) -> &Value {
    match value.get("data") {
        Some(data) if data.is_object() => data,
        _ => value,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn join_collapses_double_slash() {
        assert_eq!(join_url("https://api.mooze.app", "/users/me"), "https://api.mooze.app/users/me");
        assert_eq!(
            join_url("https://api.mooze.app/v1/", "/phone/verify"),
            "https://api.mooze.app/v1/phone/verify"
        );
        assert_eq!(join_url("https://a", "https://b/c"), "https://b/c");
    }

    #[test]
    fn encode_segment() {
        assert_eq!(encode_path_segment("ABC-12_x"), "ABC-12_x");
        assert_eq!(encode_path_segment("a b/c"), "a%20b%2Fc");
    }

    #[test]
    fn envelope() {
        let wrapped = json!({"data": {"a": 1}});
        assert_eq!(data_or_self(&wrapped), &json!({"a": 1}));
        let flat = json!({"a": 1, "data": null});
        assert_eq!(data_or_self(&flat), &flat);
        let scalar = json!({"data": "x"});
        assert_eq!(data_or_self(&scalar), &json!("x"));
        assert_eq!(data_object_or_self(&scalar), &scalar);
    }
}
