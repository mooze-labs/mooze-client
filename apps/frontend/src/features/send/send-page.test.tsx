import { it, expect, vi, afterEach } from "vitest";
import {
  render,
  screen,
  fireEvent,
  waitFor,
  cleanup,
} from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { SendPage } from "./send-page";
import { fakeClient } from "../../testing/client";
afterEach(cleanup);
async function review(onSent = vi.fn()) {
  const c = fakeClient();
  vi.mocked(c.reviewSend).mockResolvedValue({
    id: "r",
    generation: 1,
    expires_at_ms: Date.now() + 60000,
    fee_sat: 100,
    total_sat: 1100,
    request: {
      chain: "Bitcoin",
      destination: "tb1-test",
      amount_sat: 1000,
      fee_rate_sat_per_vbyte: 1,
    },
  });
  render(
    <MemoryRouter>
      <SendPage client={c} generation={1} onSent={onSent} />
    </MemoryRouter>,
  );
  fireEvent.change(screen.getByLabelText("Endereço de destino"), {
    target: { value: "tb1-test" },
  });
  fireEvent.change(screen.getByLabelText("Quantidade (BTC)"), {
    target: { value: "0,00001" },
  });
  fireEvent.click(screen.getByText("Revisar envio"));
  await screen.findByText("Confirmar envio");
  return c;
}
it("confirms a one-use review once despite repeated clicks", async () => {
  const c = await review();
  vi.mocked(c.confirmSend).mockReturnValue(new Promise(() => {}));
  fireEvent.click(screen.getByText("Confirmar envio"));
  fireEvent.click(screen.getByText("Enviando…"));
  expect(c.confirmSend).toHaveBeenCalledTimes(1);
  expect(c.confirmSend).toHaveBeenCalledWith("r");
});
it("does not offer automatic resend after an uncertain submission", async () => {
  const c = await review();
  vi.mocked(c.confirmSend).mockRejectedValue({
    code: "submission_unknown",
    message: "Resultado incerto",
  });
  fireEvent.click(screen.getByText("Confirmar envio"));
  await waitFor(() =>
    expect(screen.getByText("Verificando o resultado")).toBeInTheDocument(),
  );
  expect(c.confirmSend).toHaveBeenCalledTimes(1);
  expect(screen.queryByText("Confirmar envio")).not.toBeInTheDocument();
});
it("shows an unresolved host submission after returning to Send", () => {
  const c = fakeClient();
  render(
    <MemoryRouter>
      <SendPage
        client={c}
        generation={2}
        onSent={vi.fn()}
        submission={{ phase: "uncertain", chain: "Bitcoin", tx_id: null }}
      />
    </MemoryRouter>,
  );
  expect(screen.getByText("Verificando o resultado")).toBeInTheDocument();
  expect(screen.queryByText("Revisar envio")).not.toBeInTheDocument();
});

it("refreshes the retained host outcome after a late failure on an unmounted route", async () => {
  const changed = vi.fn();
  const c = await review(changed);
  let reject!: (reason: unknown) => void;
  vi.mocked(c.confirmSend).mockReturnValue(
    new Promise((_, r) => {
      reject = r;
    }),
  );
  fireEvent.click(screen.getByText("Confirmar envio"));
  cleanup();
  reject({ code: "submission_unknown", message: "unknown" });
  await waitFor(() => expect(changed).toHaveBeenCalledTimes(1));
});
