//! Writes `types.ts` (every DTO) and `client.ts` (the `CoreClient` interface).
//! Usage: `cargo run --features codegen --bin codegen [out_dir]`.
//! Default `out_dir`: `crates/mooze-app/generated`.

use std::path::PathBuf;

use mooze_app::methods::{ts_config, METHODS};
use ts_rs::TS;

fn camel(s: &str) -> String {
    let mut out = String::new();
    let mut up = false;
    for c in s.chars() {
        if c == '_' {
            up = true;
            continue;
        }
        if up {
            out.extend(c.to_uppercase());
            up = false;
        } else {
            out.push(c);
        }
    }
    out
}

/// Prefixes DTO names with `T.`; leaves TypeScript primitives alone.
fn qualify(ts: &str) -> String {
    let primitives = [
        "string",
        "number",
        "bigint",
        "boolean",
        "null",
        "undefined",
        "Array",
    ];
    let mut out = String::new();
    let mut word = String::new();
    let flush = |word: &mut String, out: &mut String| {
        if word.is_empty() {
            return;
        }
        if primitives.contains(&word.as_str()) {
            out.push_str(word);
        } else {
            out.push_str("T.");
            out.push_str(word);
        }
        word.clear();
    };
    for c in ts.chars() {
        if c.is_alphanumeric() || c == '_' {
            word.push(c);
        } else {
            flush(&mut word, &mut out);
            out.push(c);
        }
    }
    flush(&mut word, &mut out);
    out
}

/// Names of TypeScript types that `referenced` mentions but `declared`
/// does not define. Builtins and the `T` import alias are ignored.
fn missing_exports(declared: &[String], referenced: &[&str]) -> Vec<String> {
    let builtins = [
        "T",
        "string",
        "number",
        "bigint",
        "boolean",
        "null",
        "undefined",
        "never",
        "unknown",
        "Array",
        "Record",
        "Promise",
        "Map",
        "Set",
        "Partial",
    ];
    let mut missing: Vec<String> = Vec::new();
    for text in referenced {
        let text = strip_comments_and_strings(text);
        let mut word = String::new();
        for c in text.chars().chain(std::iter::once(' ')) {
            if c.is_alphanumeric() || c == '_' {
                word.push(c);
                continue;
            }
            if word.chars().next().is_some_and(|f| f.is_ascii_uppercase())
                && !builtins.contains(&word.as_str())
                && !declared.iter().any(|d| d == &word)
                && !missing.contains(&word)
            {
                missing.push(word.clone());
            }
            word.clear();
        }
    }
    missing.sort();
    missing
}

/// Removes `/* */` and `//` comments and double-quoted string literals,
/// which carry words but never type references.
fn strip_comments_and_strings(text: &str) -> String {
    let mut out = String::new();
    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        match c {
            '/' if chars.peek() == Some(&'*') => {
                chars.next();
                let mut prev = ' ';
                for c in chars.by_ref() {
                    if prev == '*' && c == '/' {
                        break;
                    }
                    prev = c;
                }
                out.push(' ');
            }
            '/' if chars.peek() == Some(&'/') => {
                for c in chars.by_ref() {
                    if c == '\n' {
                        break;
                    }
                }
                out.push(' ');
            }
            '"' => {
                for c in chars.by_ref() {
                    if c == '"' {
                        break;
                    }
                }
                out.push(' ');
            }
            c => out.push(c),
        }
    }
    out
}

fn main() {
    let out = std::env::args()
        .nth(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("generated"));
    std::fs::create_dir_all(&out).expect("create out dir");

    // types.ts: one file, every exported type, sorted by name.
    let cfg = ts_config();
    let mut decls: Vec<(String, String)> = Vec::new();
    macro_rules! export {
        ($($t:ty),* $(,)?) => { $( decls.push((<$t as TS>::name(&cfg), <$t as TS>::decl(&cfg))); )* };
    }
    use mooze_app::dto::*;
    use mooze_app::events::AppEvent;
    use mooze_app::{AppError, ErrorCode};
    export!(
        AppError,
        ErrorCode,
        AppEvent,
        NetworkDto,
        BackendDto,
        AppConfig,
        ChainDto,
        DirectionDto,
        StatusDto,
        SourceDto,
        TransactionDto,
        TransactionEventKindDto,
        TransactionEventDto,
        AssetBalanceDto,
        BalanceDto,
        SyncOutcomeDto,
        FeePriorityDto,
        SendRequestDto,
        FeeEstimateDto,
        ReceiveAddressDto,
        BroadcastResultDto,
        LiquidSendDraftDto,
        LiquidUtxoDto,
        KeychainDto,
        DerivedAddressDto,
        WalletUtxoDto,
        AddressOwnershipDto,
        NextUnusedAddressDto,
        TableCountDto,
        SkippedRowDto,
        MigrationReportDto,
        AuthEnsureKind,
        AuthEnsureDto,
        HttpMethodDto,
        ApiResponseDto,
        DeviceMetricsDto,
        SyncPhaseDto,
        SyncStateDto,
        SessionLockStateDto,
        StartConfigDto,
        DepositStatusDto,
        PixDepositDto,
        PixStatusEventDto,
        PixFeeDto,
        DepositLimitsDto,
        DepositValidationErrorDto,
        DepositValidationDto,
        FavoritePayerDto,
        FavoritePayerSaveErrorDto,
        PixFlagDto,
        CpfValidationErrorDto,
        QuoteStatusDto,
        QuoteDto,
        SideSwapEventKind,
        SideSwapEventDto,
        StartQuoteDto,
        SideswapMarketDto,
        SideswapAssetDto,
        PegDirectionDto,
        PegPhaseDto,
        PegServerLimitsDto,
        PegQuoteDto,
        PegOrderDto,
        PegExecutionDto,
        TrackedPegDto,
        PegRefreshDto,
        PegProgressDto,
        PegRecordDto,
        PegAmountIssueDto,
        PegAmountValidationDto,
    );
    decls.sort();
    decls.dedup();
    let declared: Vec<String> = decls.iter().map(|(n, _)| n.clone()).collect();
    let mut referenced: Vec<String> = decls.iter().map(|(_, d)| d.clone()).collect();
    for m in METHODS {
        referenced.extend(m.params.iter().map(|(_, t)| t()));
        referenced.push((m.returns)());
    }
    let refs: Vec<&str> = referenced.iter().map(String::as_str).collect();
    let missing = missing_exports(&declared, &refs);
    assert!(
        missing.is_empty(),
        "types referenced but not in the export! list: {missing:?}"
    );
    let mut types = String::from(
        "// Generated by `cargo run --features codegen --bin codegen`. Do not edit.\n\n",
    );
    for (_, d) in &decls {
        types.push_str("export ");
        types.push_str(d);
        types.push_str("\n\n");
    }
    std::fs::write(out.join("types.ts"), types).expect("write types.ts");

    // client.ts
    let mut client = String::from(
        "// Generated by `cargo run --features codegen --bin codegen`. Do not edit.\nimport type * as T from \"./types\";\n\n",
    );
    client.push_str("export interface CoreClient {\n");
    for m in METHODS {
        let params: Vec<String> = m
            .params
            .iter()
            .map(|(n, t)| format!("{}: {}", camel(n), qualify(&t())))
            .collect();
        let ret = qualify(&(m.returns)());
        client.push_str(&format!(
            "  {}({}): Promise<{}>;\n",
            camel(m.name),
            params.join(", "),
            ret
        ));
    }
    client.push_str("}\n\nexport const METHOD_NAMES = [\n");
    for m in METHODS {
        client.push_str(&format!("  \"{}\",\n", m.name));
    }
    client.push_str("] as const;\n");
    std::fs::write(out.join("client.ts"), client).expect("write client.ts");
}

#[cfg(test)]
mod tests {
    use super::missing_exports;

    #[test]
    fn referenced_types_must_be_declared() {
        let declared = ["BalanceDto", "ChainDto", "NetworkDto"].map(String::from).to_vec();
        let referenced = [
            "{ chain: ChainDto, assets: Array<AssetBalanceDto>, when: string | null }",
            "Promise<Array<T.BalanceDto>>",
            "Record<string, number>",
            "/** The Mainnet wallet. Bitcoin only. */ type NetworkDto = \"Mainnet\" | \"Testnet\";",
            "{ a: number, // Height of the Block\n b: string }",
        ];
        let missing = missing_exports(&declared, &referenced);
        assert_eq!(missing, vec!["AssetBalanceDto"]);
    }
}
