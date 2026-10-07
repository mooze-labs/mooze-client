import { AccountPage } from "../features/account/account-page";
import { ScreenTransition } from "../ui/screen-transition";
import { SwapPage } from "../features/swap/swap-page";
import { PixPage } from "../features/pix/pix-page";
import { BackendStatus } from "../features/dashboard/backend-status";
import { NetworkContext, networkLabel } from "../core/network";
import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { NavLink, Routes, Route } from "react-router-dom";
import {
  Wallet,
  UserRound,
  Clock,
  Settings,
  Eye,
  EyeOff,
  Lock,
  QrCode,
  ArrowLeftRight,
} from "lucide-react";
import { useT } from "../i18n/messages";
import { usePreferences } from "../i18n/preferences";
import { useWalletClient } from "./client-context";
import { useWalletSession, useWalletSnapshot } from "./session-provider";
import { errorText } from "../core/client";
import { Button, ErrorNotice } from "../ui";
import { PrivacyContext } from "../ui/sensitive-value";
import { SettingsPage } from "../features/settings/settings-page";
import { RemovalPending } from "../features/settings/remove-wallet-dialog";
import { SendDraftProvider } from "../features/send/send-draft";
import { SendPage } from "../features/send/send-page";
import { NetworkStatus } from "../features/dashboard/network-status";
import { DashboardPage } from "../features/dashboard/dashboard-page";
import { AssetsPage, AssetPage } from "../features/assets/assets-page";
import { ReceivePage } from "../features/receive/receive-page";
import { HistoryPage } from "../features/history/history-page";
import { SetupPage } from "../features/setup/setup-page";
import { SessionScreen } from "../features/session/session-screen";
const links = [
  ["/", "Carteira", Wallet],
  ["/pix", "Pix", QrCode],
  ["/swap", "Trocar", ArrowLeftRight],
  ["/history", "Atividade", Clock],
  ["/account", "Conta", UserRound],
  ["/settings", "Ajustes", Settings],
] as const;
export function WalletShell() {
  const client = useWalletClient();
  const host = useQuery({
    queryKey: ["host"],
    queryFn: () => client.hostInfo(),
  });
  return (
    <NetworkContext.Provider value={host.data?.network ?? ""}>
      <WalletShellContent />
    </NetworkContext.Provider>
  );
}
function WalletShellContent() {
  const t = useT();
  const qc = useQueryClient();
  const client = useWalletClient();
  const { session, startupError, update, setStartupError } = useWalletSession();
  const { preferences, save } = usePreferences();
  const privateMode = preferences.privacy;
  const [preferencesError, setPreferencesError] = useState("");
  const host = useQuery({
    queryKey: ["host"],
    queryFn: () => client.hostInfo(),
  });
  const snapshot = useWalletSnapshot();
  if (startupError)
    return (
      <main className="onboarding">
        <ErrorNotice>{startupError}</ErrorNotice>
        <Button onClick={() => location.reload()}>
          {t("Tentar novamente")}
        </Button>
      </main>
    );
  if (!session)
    return (
      <main className="onboarding">
        <p>{t("Iniciando Mooze…")}</p>
      </main>
    );
  if (session.status === "removal_pending") return <RemovalPending />;
  if (session.status === "empty")
    return <SetupPage client={client} onSession={update} />;
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
    <NetworkContext.Provider value={host.data?.network ?? ""}>
      <PrivacyContext.Provider value={privateMode}>
        <div className="shell">
          <aside>
            <div className="wordmark">
              {t("mooze")}
              <span>●</span>
            </div>
            <nav>
              {links.map(([to, label, Icon]) => (
                <div key={to}>
                  <NavLink to={to} end={to === "/"}>
                    <Icon size={18} />
                    {t(label)}
                  </NavLink>
                </div>
              ))}
            </nav>
            <footer>
              {networkLabel(host.data?.network) && (
                <span className="network-badge">
                  {networkLabel(host.data?.network)}
                </span>
              )}
              <NetworkStatus />
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
                {t("Bloquear carteira")}
              </Button>
            </footer>
          </aside>
          <div className="workspace">
            <header>
              <div className="header-context">
                {host.data?.pix_enabled && <BackendStatus />}
              </div>
              <div className="header-right">
                <Button
                  className="icon-button"
                  aria-label={
                    privateMode ? t("Mostrar valores") : t("Ocultar valores")
                  }
                  onClick={() => {
                    void save({ ...preferences, privacy: !privateMode })
                      .then(() => setPreferencesError(""))
                      .catch((e) => setPreferencesError(errorText(e)));
                  }}
                >
                  {privateMode ? <EyeOff size={18} /> : <Eye size={18} />}
                </Button>
              </div>
            </header>
            <main className="content">
              <ErrorNotice>{preferencesError}</ErrorNotice>
              <ErrorNotice>
                {snapshot.error
                  ? errorText(snapshot.error)
                  : host.error
                    ? errorText(host.error)
                    : ""}
              </ErrorNotice>
              {snapshot.data?.submission?.phase === "uncertain" && (
                <div className="notice">
                  {t("Há um envio com resultado incerto.")}{" "}
                  <NavLink to="/send">{t("Verificar resultado")}</NavLink>
                  {t("antes de enviar novamente.")}
                </div>
              )}
              {host.data && (
                <SendDraftProvider key={session.generation}>
                  <ScreenTransition>
                    <Routes>
                      <Route path="/swap" element={<SwapPage />} />
                      <Route path="/pix" element={<PixPage />} />
                      <Route
                        path="/assets"
                        element={<AssetsPage data={snapshot.data} />}
                      />
                      <Route
                        path="/"
                        element={
                          <DashboardPage
                            data={snapshot.data}
                            host={host.data}
                          />
                        }
                      />
                      <Route
                        path="/assets/:chain/:assetKey"
                        element={<AssetPage data={snapshot.data} />}
                      />
                      <Route
                        path="/history"
                        element={<HistoryPage data={snapshot.data} />}
                      />
                      <Route path="/receive" element={<ReceivePage />} />
                      <Route
                        path="/send"
                        element={
                          <SendPage
                            client={client}
                            generation={session.generation}
                            submission={snapshot.data?.submission}
                            activity={snapshot.data?.activity}
                            onSent={() =>
                              void qc.invalidateQueries({
                                queryKey: ["wallet"],
                              })
                            }
                          />
                        }
                      />
                      <Route path="/account" element={<AccountPage />} />
                      <Route path="/settings" element={<SettingsPage />} />
                      <Route
                        path="*"
                        element={
                          <DashboardPage
                            data={snapshot.data}
                            host={host.data}
                          />
                        }
                      />
                    </Routes>
                  </ScreenTransition>
                </SendDraftProvider>
              )}
            </main>
          </div>
        </div>
      </PrivacyContext.Provider>
    </NetworkContext.Provider>
  );
}
