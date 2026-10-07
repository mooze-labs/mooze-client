import { useEffect, useState } from "react";
import { useQueries } from "@tanstack/react-query";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { useNetwork } from "../../core/network";
import type { HoldingView } from "../dashboard/holdings-model";
import type { PriceMarketDto } from "../../core/desktop.generated";
import { priceMarket } from "./price-model";
import {
  MAX_RATE_AGE_MS,
  holdingFiat,
  latestRate,
  summarizeFiat,
  type FiatRates,
} from "./holding-fiat";
export function useHoldingFiat(rows: HoldingView[]) {
  const client = useWalletClient();
  const { session } = useWalletSession();
  const network = useNetwork();
  const markets = [
    ...new Set(
      rows
        .filter(
          (row) =>
            row.balanceText !== null &&
            !row.stale &&
            BigInt(row.balance_units) > 0n,
        )
        .map((row) => priceMarket(row.metadata, network))
        .filter((market): market is PriceMarketDto => market !== null),
    ),
  ];
  const queries = useQueries({
    queries: markets.map((market) => ({
      queryKey: [
        "wallet",
        session?.generation,
        "price-history",
        market,
        "brl",
        1,
      ],
      queryFn: () => client.priceHistory(market, "brl", 1),
      enabled: session?.status === "unlocked",
      staleTime: 300_000,
      refetchInterval: 300_000,
      retry: false,
      refetchOnWindowFocus: false,
    })),
  });
  const rates: FiatRates = Object.fromEntries(
    markets.map((market, i) => [
      market,
      latestRate(queries[i].data, Date.now()),
    ]),
  );
  const [, refreshClock] = useState(0);
  const validRates = Object.values(rates).filter((rate) => rate != null);
  const expiresAt = validRates.length
    ? Math.min(
        ...validRates.map((rate) => rate.timestamp + MAX_RATE_AGE_MS + 1),
      )
    : null;
  useEffect(() => {
    const refresh = () => refreshClock((value) => value + 1);
    const timer =
      expiresAt === null
        ? undefined
        : window.setTimeout(refresh, Math.max(0, expiresAt - Date.now()));
    window.addEventListener("focus", refresh);
    document.addEventListener("visibilitychange", refresh);
    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("focus", refresh);
      document.removeEventListener("visibilitychange", refresh);
    };
  }, [expiresAt]);
  const values = rows.map((row) => holdingFiat(row, network, rates));
  return {
    values: Object.fromEntries(rows.map((row, i) => [row.key, values[i]])),
    total: summarizeFiat(rows, values),
    loading: queries.some((query) => query.isPending),
    refreshFailed: queries.some((query) => query.isError),
    rates: Object.values(rates).filter((rate) => rate != null),
    retry: () => {
      queries.forEach((query) => {
        void query.refetch();
      });
    },
  };
}
