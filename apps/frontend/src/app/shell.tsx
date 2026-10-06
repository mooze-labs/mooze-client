import { PrivacyContext, SensitiveValue } from "../ui/sensitive-value";
import { Activity, transactionAmount } from "../features/history/activity";
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
import { DashboardPage } from "../features/dashboard/dashboard-page";
import { AssetsPage, AssetPage } from "../features/assets/assets-page";
const links = [
  ["/", "Início", Home],
  ["/assets", "Ativos", Wallet],
  ["/history", "Histórico", Clock],
  ["/receive", "Receber", ArrowDownLeft],
  ["/send", "Enviar", ArrowUpRight],
  ["/settings", "Ajustes", Settings],
] as const;
export function WalletShell() {
  const qc = useQueryClient();
  const client = useWalletClient();
  const { session, startupError, update, setStartupError } = useWalletSession();
  const [privateMode, setPrivate] = useState(
    () => localStorage.getItem("mooze.privacy") === "true",
  );
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
    <PrivacyContext.Provider value={privateMode}>
      <div className="shell">
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
                <NavLink to="/send">Verificar resultado</NavLink> antes de
                enviar novamente.
              </div>
            )}
            {host.data && (
              <Routes>
                <Route
                  path="/assets"
                  element={<AssetsPage data={snapshot.data} />}
                />
                <Route
                  path="/"
                  element={
                    <DashboardPage data={snapshot.data} host={host.data} />
                  }
                />
                <Route
                  path="/assets/:chain/:assetKey"
                  element={<AssetPage data={snapshot.data} />}
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
                  element={
                    <DashboardPage data={snapshot.data} host={host.data} />
                  }
                />
              </Routes>
            )}
          </main>
        </div>
      </div>
    </PrivacyContext.Provider>
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
function Amount({ value, ticker }: { value: number; ticker: string }) {
  return (
    <SensitiveValue>
      {formatBaseUnits(BigInt(value))} <small>{ticker}</small>
    </SensitiveValue>
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
                    <SensitiveValue>
                      {transactionAmount(t, host)}
                    </SensitiveValue>
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
