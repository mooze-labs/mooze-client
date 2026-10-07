import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import type { AssetMetadataDto } from "../../../../../crates/mooze-app/generated/types";
import type { PriceHistoryDto } from "../../core/desktop.generated";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { useNetwork } from "../../core/network";
import { useT } from "../../i18n/messages";
import { usePreferences } from "../../i18n/preferences";
import { Button } from "../../ui";
import { chartGeometry, priceMarket } from "./price-model";
export function AssetPriceChart({ asset }: { asset: AssetMetadataDto }) {
  const t = useT();
  const client = useWalletClient();
  const { session } = useWalletSession();
  const network = useNetwork();
  const market = priceMarket(asset, network);
  const [days, setDays] = useState<1 | 7 | 30>(7);
  const [currency, setCurrency] = useState<"brl" | "usd">("brl");
  const query = useQuery({
    queryKey: [
      "wallet",
      session?.generation,
      "price-history",
      market,
      currency,
      days,
    ],
    queryFn: () => client.priceHistory(market!, currency, days),
    enabled: !!market && session?.status === "unlocked",
    staleTime: 300_000,
    gcTime: 1_800_000,
    retry: false,
    refetchOnWindowFocus: false,
  });
  return (
    <section className="card section-gap asset-price-chart">
      <div className="price-chart-heading">
        <div>
          <h2>{t("Preço de mercado")}</h2>
          <p className="muted small">
            {t(
              market === "Bitcoin" && asset.key.chain === "Liquid"
                ? "Referência de preço: Bitcoin (BTC)."
                : "Preço de uma unidade do ativo, independente do saldo da carteira.",
            )}
          </p>
        </div>
        {market && (
          <div className="chart-controls">
            <div role="group" aria-label={t("Período do gráfico")}>
              {([1, 7, 30] as const).map((period) => (
                <Button
                  key={period}
                  aria-pressed={days === period}
                  onClick={() => setDays(period)}
                >
                  {period === 30 ? "1M" : `${period}D`}
                </Button>
              ))}
            </div>
            <div role="group" aria-label={t("Moeda do gráfico")}>
              {(["brl", "usd"] as const).map((code) => (
                <Button
                  key={code}
                  aria-pressed={currency === code}
                  onClick={() => setCurrency(code)}
                >
                  {code.toUpperCase()}
                </Button>
              ))}
            </div>
          </div>
        )}
      </div>
      {!market ? (
        <p className="muted">
          {t("Histórico de mercado indisponível para este ativo.")}
        </p>
      ) : (
        <>
          {query.isPending && (
            <div className="chart-placeholder" role="status">
              {t("Carregando preços…")}
            </div>
          )}
          {query.isError && (
            <div className="notice" role="status">
              <p>
                {t(
                  query.data
                    ? "Não foi possível atualizar. Os preços abaixo podem estar desatualizados."
                    : "Preços indisponíveis. O serviço pode estar temporariamente limitado.",
                )}
              </p>
              <Button
                disabled={query.isFetching}
                onClick={() => void query.refetch()}
              >
                {t("Tentar novamente")}
              </Button>
            </div>
          )}
          {query.data && (
            <PricePlot
              key={`${market}-${currency}-${days}`}
              data={query.data}
              currency={currency}
            />
          )}
        </>
      )}
    </section>
  );
}
export function PricePlot({
  data,
  currency,
}: {
  data: PriceHistoryDto;
  currency: "brl" | "usd";
}) {
  const t = useT();
  const { preferences } = usePreferences();
  const [selected, setSelected] = useState<number | null>(null);
  if (data.points.length < 2)
    return <p>{t("Histórico de mercado indisponível para este ativo.")}</p>;
  const geometry = chartGeometry(data.points);
  const index = Math.min(
    selected ?? data.points.length - 1,
    data.points.length - 1,
  );
  const point = data.points[index];
  const position = geometry.coordinates[index];
  const money = (price: number) =>
    new Intl.NumberFormat(preferences.locale, {
      style: "currency",
      currency: currency.toUpperCase(),
      maximumFractionDigits: currency === "usd" && geometry.max < 10 ? 4 : 2,
    }).format(price);
  const date = (timestamp: number) =>
    new Date(timestamp).toLocaleString(preferences.locale, {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  return (
    <div className="price-plot">
      <div className="price-chart-summary">
        <div>
          <strong className="market-price">{money(point.price)}</strong>
          <p className="muted small">{date(point.timestamp_ms)}</p>
        </div>
        <span className="market-change" data-positive={geometry.change >= 0}>
          {new Intl.NumberFormat(preferences.locale, {
            signDisplay: "always",
            maximumFractionDigits: 2,
          }).format(geometry.change)}
          % <span className="muted small">{t("no período")}</span>
        </span>
      </div>
      <div className="price-axis muted small">
        <span>
          {t("Máxima")}: {money(geometry.max)}
        </span>
        <span>
          {t("Mínima")}: {money(geometry.min)}
        </span>
      </div>
      <svg
        viewBox="0 0 720 200"
        role="img"
        aria-label={`${t("Variação do preço")}: ${money(data.points[0].price)} – ${money(data.points.at(-1)!.price)}`}
        onPointerLeave={() => setSelected(null)}
        onPointerMove={(event) => {
          const box = event.currentTarget.getBoundingClientRect();
          const x = Math.max(
            0,
            Math.min(
              1,
              (((event.clientX - box.left) / box.width) * 720 - 12) / 696,
            ),
          );
          const target =
            data.points[0].timestamp_ms +
            x *
              (data.points.at(-1)!.timestamp_ms - data.points[0].timestamp_ms);
          let nearest = 0;
          data.points.forEach((p, i) => {
            if (
              Math.abs(p.timestamp_ms - target) <
              Math.abs(data.points[nearest].timestamp_ms - target)
            )
              nearest = i;
          });
          setSelected(nearest);
        }}
      >
        {[40, 100, 160].map((y) => (
          <line key={y} x1="12" x2="708" y1={y} y2={y} className="chart-grid" />
        ))}
        <path
          d={geometry.path}
          fill="none"
          stroke="currentColor"
          strokeWidth="2.5"
          vectorEffect="non-scaling-stroke"
          className={geometry.change >= 0 ? "chart-positive" : "chart-negative"}
        />
        <line
          x1={position.x}
          x2={position.x}
          y1="12"
          y2="188"
          className="chart-cursor"
        />
        <circle cx={position.x} cy={position.y} r="4" fill="currentColor" />
      </svg>
      <div className="price-axis muted small">
        <span>{date(data.points[0].timestamp_ms)}</span>
        <span>{date(data.points.at(-1)!.timestamp_ms)}</span>
      </div>
      <input
        className="chart-scrubber"
        type="range"
        aria-label={t("Explorar preços no período")}
        aria-valuetext={`${date(point.timestamp_ms)}: ${money(point.price)}`}
        min={0}
        max={data.points.length - 1}
        value={index}
        onChange={(event) => setSelected(Number(event.target.value))}
      />
      <p className="muted small chart-attribution">
        {t("Fonte")}: {data.source} · {t("Atualizado em")}:{" "}
        {date(data.fetched_at_ms)}
      </p>
    </div>
  );
}
