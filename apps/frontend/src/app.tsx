import { client, inDesktop } from "./core/tauri";
import {WalletClientProvider} from "./app/client-context";
import {SessionProvider} from "./app/session-provider";
import {WalletShell} from "./app/shell";
export function App() {
 if (!inDesktop()) return <main className="onboarding"><div className="wordmark">mooze<span>●</span></div><section className="card import-card"><h1>Abra o aplicativo desktop</h1><p>Inicie o aplicativo Mooze Testnet para acessar sua carteira.</p></section></main>;
 return <WalletClientProvider client={client}><SessionProvider><WalletShell /></SessionProvider></WalletClientProvider>;
}
