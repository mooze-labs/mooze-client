import { SensitiveValue } from "../../ui/sensitive-value";
import { ArrowDownLeft, ArrowUpRight, Clock } from "lucide-react";
import type { TransactionDto } from "../../../../../crates/mooze-app/generated/types";
import type { HostInfo } from "../../core/client";
import { formatBaseUnits } from "../send/amount";
export function transactionAmount(t: TransactionDto, host: HostInfo) {
  return t.chain === "Bitcoin" || t.asset_id === host.liquid_policy_asset
    ? formatBaseUnits(BigInt(t.amount_sat)) +
        " " +
        (t.chain === "Bitcoin" ? "BTC" : "L-BTC")
    : String(t.amount_sat) + " unidades brutas";
}
export function Activity({
  rows,
  host,
}: {
  rows: TransactionDto[];
  host: HostInfo;
}) {
  return rows.length ? (
    <div>
      {rows.map((t) => (
        <div className="activity" key={t.chain + t.id}>
          <span className="activity-icon">
            {t.direction === "Incoming" ? (
              <ArrowDownLeft size={18} />
            ) : (
              <ArrowUpRight size={18} />
            )}
          </span>
          <div>
            <strong>
              {t.direction === "Incoming"
                ? "Recebido"
                : t.direction === "SelfTransfer"
                  ? "Transferência própria"
                  : "Enviado"}
            </strong>
            <p className="small muted">
              {t.chain} · {t.status === "Confirmed" ? "Confirmado" : "Pendente"}
            </p>
          </div>
          <SensitiveValue>{transactionAmount(t, host)}</SensitiveValue>
        </div>
      ))}
    </div>
  ) : (
    <div className="empty">
      <Clock size={23} />
      <p>Nenhuma transação por enquanto</p>
    </div>
  );
}
