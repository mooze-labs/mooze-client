import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  NavLink,
  Routes,
  Route,
  useLocation,
  useNavigate,
  useParams,
} from "react-router-dom";
import {
  Home,
  Wallet,
  Clock,
  ArrowDownLeft,
  ArrowUpRight,
  Settings,
  Eye,
  EyeOff,
  Lock,
  RefreshCw,
  Copy,
  ArrowRight,
  ChartNoAxesCombined,
} from "lucide-react";
import { QRCodeSVG } from "qrcode.react";
import { useWalletClient } from "./client-context";
import { useWalletSession, useWalletSnapshot } from "./session-provider";
import type { Chain, Session, Snapshot, HostInfo } from "../core/client";
import { errorText } from "../core/client";
import { SessionScreen } from "../features/session/session-screen";
import { formatBaseUnits } from "../features/send/amount";
import { SendPage } from "../features/send/send-page";
import { Button, ErrorNotice } from "../ui";
import type { TransactionDto } from "../../../../crates/mooze-app/generated/types";
const links = [
  ["/", "Início", Home],
  ["/assets/Bitcoin", "Ativos", Wallet],
  ["/history", "Histórico", Clock],
  ["/receive", "Receber", ArrowDownLeft],
  ["/send", "Enviar", ArrowUpRight],
  ["/settings", "Ajustes", Settings],
] as const;
export function WalletShell() {
  const qc = useQueryClient();
  const client = useWalletClient();
  const {session,startupError,update,setStartupError} = useWalletSession();
  const [privateMode,setPrivate] = useState(() => localStorage.getItem("mooze.privacy") === "true");
  const host = useQuery({
    queryKey: ["host"],
    queryFn: () => client.hostInfo(),
  });
  const snapshot = useWalletSnapshot();
  if (startupError)
    return (
      <main className="onboarding">
        <ErrorNotice>{startupError}</ErrorNotice>
        <Button onClick={() => location.reload()}>Tentar novamente</Button>
      </main>
    );
  if (!session)
    return (
      <main className="onboarding">
        <p>Iniciando Mooze…</p>
      </main>
    );
  if (session.status !== "unlocked")
    return (
      <SessionScreen
        key={session.status}
        client={client}
        session={session}
        onSession={update}
      />
    );
  return (
    <div className={`shell ${privateMode ? "privacy" : ""}`}>
      <aside>
        <div className="wordmark">
          mooze<span>●</span>
        </div>
        <nav>
          {links.map(([to, label, Icon], i) => (
            <div key={to}>
              {i === 3 && <p className="nav-label">OPERAR</p>}
              {i === 5 && <hr />}
              <NavLink to={to} end={to === "/"}>
                <Icon size={18} />
                {label}
              </NavLink>
            </div>
          ))}
        </nav>
        <footer>
          <span className="network-badge">TESTNET</span>
          <p>
            <span className="status-dot" />
            Bitcoin + Liquid
          </p>
          <p className="small muted">Chaves neste computador</p>
          <Button
            className="ghost"
            onClick={() =>
              void client
                .lock()
                .then(update)
                .catch((e) => setStartupError(errorText(e)))
            }
          >
            <Lock size={14} />
            Bloquear carteira
          </Button>
        </footer>
      </aside>
      <div className="workspace">
        <header>
          <PageTitle />
          <div className="header-right">
            <span className="muted small">
              {snapshot.isFetching
                ? "Atualizando…"
                : snapshot.data?.chains.length === 2 &&
                    snapshot.data.chains.every((c) => c.phase === "ready")
                  ? "Redes sincronizadas"
                  : "Aguardando sincronização"}
            </span>
            <span className="network-badge">REDE DE TESTES</span>
            <Button
              className="icon-button"
              aria-label={privateMode ? "Mostrar valores" : "Ocultar valores"}
              onClick={() => {
                const v = !privateMode;
                setPrivate(v);
                localStorage.setItem("mooze.privacy", String(v));
              }}
            >
              {privateMode ? <EyeOff size={18} /> : <Eye size={18} />}
            </Button>
          </div>
        </header>
        <main className="content">
          <ErrorNotice>
            {snapshot.error
              ? errorText(snapshot.error)
              : host.error
                ? errorText(host.error)
                : ""}
          </ErrorNotice>
          {snapshot.data?.submission?.phase === "uncertain" && (
            <div className="notice">
              Há um envio com resultado incerto.{" "}
              <NavLink to="/send">Verificar resultado</NavLink> antes de enviar
              novamente.
            </div>
          )}
          {host.data && (
            <Routes>
              <Route
                path="/"
                element={<Dashboard data={snapshot.data} host={host.data} />}
              />
              <Route
                path="/assets/:chain"
                element={<AssetPage data={snapshot.data} host={host.data} />}
              />
              <Route
                path="/history"
                element={
                  <History
                    rows={snapshot.data?.transactions ?? []}
                    host={host.data}
                  />
                }
              />
              <Route
                path="/receive"
                element={<Receive generation={session.generation} />}
              />
              <Route
                path="/send"
                element={
                  <SendPage
                    client={client}
                    generation={session.generation}
                    submission={snapshot.data?.submission}
                    onSent={() =>
                      void qc.invalidateQueries({ queryKey: ["wallet"] })
                    }
                  />
                }
              />
              <Route
                path="/settings"
                element={<SettingsPage host={host.data} />}
              />
              <Route
                path="*"
                element={<Dashboard data={snapshot.data} host={host.data} />}
              />
            </Routes>
          )}
        </main>
      </div>
    </div>
  );
}
function PageTitle() {
  const { pathname } = useLocation();
  return (
    <h2>
      {pathname.startsWith("/assets")
        ? "Ativos"
        : (links.find(([p]) => p === pathname)?.[1] ?? "Mooze")}
    </h2>
  );
}
function assetAmount(data: Snapshot | undefined, chain: Chain, host: HostInfo) {
  const list = chain === "Bitcoin" ? data?.bitcoin.assets : data?.liquid.assets;
  return (
    list?.find(
      (a) => chain === "Bitcoin" || a.asset_id === host.liquid_policy_asset,
    )?.amount_sat ?? 0
  );
}
function chainStatus(data: Snapshot | undefined, chain: Chain) {
  const state = data?.chains.find((s) => s.chain === chain);
  return state?.phase === "error"
    ? "Falha · tentar atualizar"
    : state?.phase === "ready"
      ? "Sincronizado"
      : "Aguardando";
}
function BalanceAmount({
  data,
  chain,
  host,
}: {
  data: Snapshot | undefined;
  chain: Chain;
  host: HostInfo;
}) {
  const state = data?.chains.find((s) => s.chain === chain);
  return state?.last_success_at_ms ? (
    <>
      <Amount
        value={assetAmount(data, chain, host)}
        ticker={chain === "Bitcoin" ? "BTC" : "L-BTC"}
      />
      {state.phase === "error" && (
        <small className="muted"> · saldo anterior</small>
      )}
    </>
  ) : (
    <span className="muted">Aguardando sincronização</span>
  );
}
function transactionAmount(t: TransactionDto, host: HostInfo) {
  return t.chain === "Bitcoin" || t.asset_id === host.liquid_policy_asset
    ? formatBaseUnits(BigInt(t.amount_sat)) +
        " " +
        (t.chain === "Bitcoin" ? "BTC" : "L-BTC")
    : String(t.amount_sat) + " unidades brutas";
}
function UnknownAssets({
  data,
  host,
}: {
  data: Snapshot | undefined;
  host: HostInfo;
}) {
  const assets =
    data?.liquid.assets.filter(
      (a) => a.asset_id !== host.liquid_policy_asset,
    ) ?? [];
  return assets.length ? (
    <div className="notice">
      <h3>Outros ativos Liquid</h3>
      {assets.map((a) => (
        <div key={a.asset_id} className="wrap small">
          <p className="mono">{a.asset_id}</p>
          <p className="sensitive">
            {a.amount_sat} unidades brutas · precisão desconhecida
          </p>
        </div>
      ))}
    </div>
  ) : null;
}
function Amount({ value, ticker }: { value: number; ticker: string }) {
  return (
    <span className="sensitive mono">
      {formatBaseUnits(BigInt(value))} <small>{ticker}</small>
    </span>
  );
}
function Dashboard({
  data,
  host,
}: {
  data: Snapshot | undefined;
  host: HostInfo;
}) {
  const client = useWalletClient();
  const navigate = useNavigate();
  const [error, setError] = useState("");
  return (
    <>
      <div className="page-heading">
        <div>
          <p className="eyebrow">VISÃO GERAL</p>
          <h1>Sua carteira</h1>
          <p className="muted">Bitcoin e Liquid, sob seu controle.</p>
        </div>
        <Button
          onClick={() =>
            void client.refresh().catch((e) => setError(errorText(e)))
          }
        >
          <RefreshCw size={15} />
          Atualizar
        </Button>
      </div>
      <ErrorNotice>{error}</ErrorNotice>
      <div className="dashboard-grid">
        <section className="card portfolio">
          <div className="card-top">
            <div>
              <p className="muted">Saldos em rede de testes</p>
              <h2>Bitcoin + Liquid</h2>
            </div>
            <div className="actions">
              <Button className="primary" onClick={() => navigate("/receive")}>
                <ArrowDownLeft size={16} />
                Receber
              </Button>
              <Button onClick={() => navigate("/send")}>
                <ArrowUpRight size={16} />
                Enviar
              </Button>
            </div>
          </div>
          <div className="balance-pair">
            {(["Bitcoin", "Liquid"] as Chain[]).map((c) => (
              <div key={c}>
                <p className="muted">
                  <span className={`asset-dot ${c}`} />
                  {c === "Bitcoin" ? "Bitcoin" : "Liquid Bitcoin"}
                </p>
                {data ? (
                  <h2>
                    <BalanceAmount data={data} chain={c} host={host} />
                  </h2>
                ) : (
                  <p>Carregando…</p>
                )}
              </div>
            ))}
          </div>
          <div className="chart-empty">
            <ChartNoAxesCombined size={32} />
            <h3>O histórico começa aqui</h3>
            <p>Histórico de patrimônio indisponível neste MVP.</p>
            <span className="small">
              Ativos de teste não possuem cotação em reais.
            </span>
          </div>
        </section>
        <section className="card">
          <p className="eyebrow">CONEXÃO</p>
          <h2>Estado da carteira</h2>
          {(["Bitcoin", "Liquid"] as Chain[]).map((c) => (
            <div className="status-row" key={c}>
              <span>
                <span className={`asset-dot ${c}`} />
                {c}
              </span>
              <span className="small muted">{chainStatus(data, c)}</span>
            </div>
          ))}
          <hr />
          <p className="muted small">
            {data?.sync?.last_error
              ? "Um nó não respondeu. Os dados podem estar desatualizados."
              : "A sincronização continua automaticamente."}
          </p>
          <div className="notice">
            Electrum · Testnet
            <br />
            <small>Saldo local até a primeira sincronização.</small>
          </div>
        </section>
        <section className="card">
          <h2>Meus ativos</h2>
          <table>
            <thead>
              <tr>
                <th>Ativo</th>
                <th>Quantidade</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {(["Bitcoin", "Liquid"] as Chain[]).map((c) => (
                <tr key={c}>
                  <td>
                    <span className={`asset-dot ${c}`} />
                    {c === "Bitcoin" ? "Bitcoin" : "Liquid Bitcoin"}
                  </td>
                  <td>
                    <BalanceAmount data={data} chain={c} host={host} />
                  </td>
                  <td>
                    <Button
                      className="ghost"
                      aria-label={`Ver ${c}`}
                      onClick={() => navigate(`/assets/${c}`)}
                    >
                      <ArrowRight size={16} />
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <UnknownAssets data={data} host={host} />
        </section>
        <section className="card">
          <div className="card-top">
            <h2>Atividade recente</h2>
            <NavLink to="/history">Ver tudo</NavLink>
          </div>
          <Activity rows={(data?.transactions ?? []).slice(0, 4)} host={host} />
        </section>
      </div>
    </>
  );
}
function Activity({ rows, host }: { rows: TransactionDto[]; host: HostInfo }) {
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
          <span className="sensitive mono">{transactionAmount(t, host)}</span>
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
function AssetPage({
  data,
  host,
}: {
  data: Snapshot | undefined;
  host: HostInfo;
}) {
  const { chain } = useParams();
  const c: Chain = chain === "Liquid" ? "Liquid" : "Bitcoin";
  return (
    <>
      <div className="tabs">
        <NavLink to="/assets/Bitcoin">Bitcoin</NavLink>
        <NavLink to="/assets/Liquid">Liquid Bitcoin</NavLink>
      </div>
      <section className="card">
        <p className="muted">{c} · Testnet</p>
        <h1>
          <BalanceAmount data={data} chain={c} host={host} />
        </h1>
        <p className="muted small">
          {c === "Bitcoin" &&
          data?.chains.find((s) => s.chain === c)?.last_success_at_ms ? (
            <>
              Pendente informado pelo núcleo:{" "}
              <Amount
                value={data.bitcoin.assets[0]?.pending_sat ?? 0}
                ticker="BTC"
              />
            </>
          ) : (
            "Saldo pendente indisponível nesta rede."
          )}
        </p>
        <div className="actions">
          <NavLink className="button primary" to={`/receive?chain=${c}`}>
            Receber
          </NavLink>
          <NavLink className="button" to={`/send?chain=${c}`}>
            Enviar
          </NavLink>
        </div>
      </section>
      <section className="card section-gap">
        <h2>Atividade</h2>
        <Activity
          rows={data?.transactions.filter((t) => t.chain === c) ?? []}
          host={host}
        />
      </section>
    </>
  );
}
function History({ rows, host }: { rows: TransactionDto[]; host: HostInfo }) {
  const [chain, setChain] = useState("all");
  const [selectedId, setSelected] = useState<string | null>(null);
  const selected = rows.find((t) => t.chain + t.id === selectedId) ?? null;
  return (
    <section className="card">
      <div className="card-top">
        <h1>Histórico</h1>
        <select
          aria-label="Filtrar rede"
          value={chain}
          onChange={(e) => setChain(e.target.value)}
        >
          <option value="all">Todas as redes</option>
          <option>Bitcoin</option>
          <option>Liquid</option>
        </select>
      </div>
      {!rows.length ? (
        <Activity rows={[]} host={host} />
      ) : (
        <table>
          <thead>
            <tr>
              <th>Rede</th>
              <th>Transação</th>
              <th>Quantidade</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {rows
              .filter((t) => chain === "all" || chain === t.chain)
              .map((t) => (
                <tr key={t.chain + t.id}>
                  <td>{t.chain}</td>
                  <td>
                    <Button
                      className="ghost mono"
                      onClick={() => setSelected(t.chain + t.id)}
                    >
                      {t.id.slice(0, 12)}…
                    </Button>
                  </td>
                  <td>
                    <span className="sensitive mono">
                      {transactionAmount(t, host)}
                    </span>
                  </td>
                  <td>
                    {t.status === "Confirmed" ? "Confirmado" : "Pendente"}
                  </td>
                </tr>
              ))}
          </tbody>
        </table>
      )}
      {selected && (
        <div className="notice">
          <h3>Detalhes da transação</h3>
          <p className="mono wrap">{selected.id}</p>
          <p className="mono wrap">Ativo: {selected.asset_id ?? "BTC"}</p>
          <p>
            Taxa: <Amount value={selected.fee_sat} ticker="" />
          </p>
          <p>Confirmações: {selected.confirmations}</p>
          <Button onClick={() => setSelected(null)}>Fechar</Button>
        </div>
      )}
    </section>
  );
}
function Receive({ generation }: { generation: number }) {
  const client = useWalletClient();
  const location = useLocation();
  const [chain, setChain] = useState<Chain>(
    new URLSearchParams(location.search).get("chain") === "Liquid"
      ? "Liquid"
      : "Bitcoin",
  );
  const [copy, setCopy] = useState("");
  const address = useQuery({
    queryKey: ["wallet", generation, "receive", chain],
    queryFn: () => client.receiveAddress(chain),
  });
  const value = address.data?.address ?? "";
  return (
    <>
      <div className="page-heading">
        <div>
          <p className="eyebrow">RECEBER</p>
          <h1>Receba na sua carteira</h1>
        </div>
      </div>
      <section className="card receive-card">
        <label className="field">
          <span>Rede</span>
          <select
            value={chain}
            onChange={(e) => {
              setChain(e.target.value as Chain);
              setCopy("");
            }}
          >
            <option value="Bitcoin">Bitcoin Testnet</option>
            <option value="Liquid">Liquid Testnet</option>
          </select>
        </label>
        <ErrorNotice>
          {address.error ? errorText(address.error) : ""}
        </ErrorNotice>
        {value ? (
          <>
            <div className="qr">
              <QRCodeSVG value={value} size={210} level="M" />
            </div>
            <p className="muted">
              Envie apenas{" "}
              {chain === "Bitcoin" ? "BTC de teste" : "L-BTC de teste"} nesta
              rede.
            </p>
            <div className="address mono">{value}</div>
            <Button
              className="primary"
              onClick={() =>
                void navigator.clipboard
                  .writeText(value)
                  .then(() => setCopy("Endereço copiado"))
                  .catch(() =>
                    setCopy("Não foi possível copiar. Selecione o endereço."),
                  )
              }
            >
              <Copy size={16} />
              Copiar endereço
            </Button>
            <p role="status" className="small">
              {copy}
            </p>
          </>
        ) : (
          <p>Gerando endereço…</p>
        )}
      </section>
    </>
  );
}
function SettingsPage({ host }: { host: HostInfo }) {
  return (
    <section className="card">
      <p className="eyebrow">MVP DESKTOP</p>
      <h1>Ajustes</h1>
      <div className="settings-row">
        <strong>Rede</strong>
        <span>Bitcoin Testnet + Liquid Testnet</span>
      </div>
      <div className="settings-row">
        <strong>Backend</strong>
        <span>{host.backend}</span>
      </div>
      <div className="settings-row">
        <strong>Bloqueio</strong>
        <span>Ao sair do aplicativo ou bloquear manualmente</span>
      </div>
      <div className="settings-row">
        <strong>Armazenamento</strong>
        <span>Credenciais no cofre do sistema operacional</span>
      </div>
      <h3>Nós Bitcoin</h3>
      {host.bitcoin_endpoints.map((e) => (
        <p key={e} className="mono wrap muted">
          {e}
        </p>
      ))}
      <h3>Nós Liquid</h3>
      {host.liquid_endpoints.map((e) => (
        <p key={e} className="mono wrap muted">
          {e}
        </p>
      ))}
    </section>
  );
}
