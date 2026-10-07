import { ArrowDown, Clock3 } from "lucide-react";
import type { AssetMetadataDto } from "../../../../../crates/mooze-app/generated/types";
import type { SwapReviewDto } from "../../core/desktop.generated";
import { useT } from "../../i18n/messages";
import { usePreferences } from "../../i18n/preferences";
import { Button } from "../../ui";
import { AssetMark } from "../../ui/asset-mark";
import { SensitiveValue } from "../../ui/sensitive-value";
import { formatBaseUnits } from "../send/amount";
import { quoteRate } from "./quote-rate";
export type SwapAssetLookup = (id: string) => AssetMetadataDto | undefined;
export function SwapAmounts({
  review,
  asset,
}: {
  review: SwapReviewDto;
  asset: SwapAssetLookup;
}) {
  const t = useT();
  return (
    <div className="swap-receipt-amounts">
      {[
        {
          label: "Você envia",
          id: review.send_asset_id,
          units: review.send_units,
        },
        {
          label: "Você recebe",
          id: review.receive_asset_id,
          units: review.receive_units,
        },
      ].map((item, index) => (
        <div key={item.label}>
          {index === 1 && (
            <ArrowDown
              className="receipt-direction"
              size={18}
              aria-hidden="true"
            />
          )}
          <div className="receipt-asset">
            {asset(item.id) && <AssetMark metadata={asset(item.id)!} />}
            <div>
              <span className="muted small">{t(item.label)}</span>
              <div className="receipt-asset-amount">
                <SensitiveValue>
                  {formatBaseUnits(BigInt(item.units))}{" "}
                  <span>{asset(item.id)?.ticker || item.id}</span>
                </SensitiveValue>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
export function SwapReview({
  review,
  confirm,
  enabled,
  asset,
  now,
}: {
  review: SwapReviewDto;
  confirm: () => void;
  enabled: boolean;
  asset: SwapAssetLookup;
  now: number;
}) {
  const t = useT();
  const { preferences } = usePreferences();
  const expired = now >= review.expires_at_ms;
  const rate = quoteRate(review.send_units, review.receive_units);
  const ticker = (id: string) => asset(id)?.ticker || id;
  return (
    <section className="card receipt transaction-receipt swap-review">
      <div className="receipt-heading">
        <h2>{t("Revisar troca")}</h2>
        <span
          className="status-label"
          data-stage={expired ? "failed" : "payment"}
        >
          {t(expired ? "Cotação expirada" : "Cotação disponível")}
        </span>
      </div>
      <SwapAmounts review={review} asset={asset} />
      <div className="receipt-meta">
        {rate && (
          <div className="review-row">
            <span>{t("Taxa de câmbio estimada")}</span>
            <span>
              1 {ticker(review.send_asset_id)} ≈{" "}
              {preferences.locale === "en" ? rate : rate.replace(".", ",")}{" "}
              {ticker(review.receive_asset_id)}
            </span>
          </div>
        )}
        {review.fees.map((fee, i) => (
          <div className="review-row" key={i}>
            <span>{t("Taxas da cotação")}</span>
            <SensitiveValue>
              {formatBaseUnits(BigInt(fee.units))} {ticker(fee.asset.asset_id!)}
            </SensitiveValue>
          </div>
        ))}
      </div>
      <p className="quote-deadline" data-expired={expired}>
        <Clock3 size={14} aria-hidden="true" />
        {expired
          ? t("Cotação expirada. Solicite uma nova cotação.")
          : t("Cotação válida por {seconds}s", {
              seconds: Math.max(
                0,
                Math.ceil((review.expires_at_ms - now) / 1000),
              ),
            })}
      </p>
      <p className="small muted">
        {t("A cotação pode mudar. Confira os valores antes de confirmar.")}
      </p>
      <Button
        className="primary"
        onClick={confirm}
        disabled={!enabled || expired}
      >
        {t("Confirmar troca")}
      </Button>
    </section>
  );
}
