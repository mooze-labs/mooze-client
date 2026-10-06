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
    is_max: false,
    generation: 1,
    expires_at_ms: Date.now() + 60000,
    fee_sat: 100,
    debits: [{ asset: { chain: "Bitcoin", asset_id: null }, units: "1100" }],
    request: {
      asset: { chain: "Bitcoin", asset_id: null },
      destination: "tb1-test",
      amount: { mode: "Exact", units: "1000" },
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
        submission={{
          version: 1,
          request: null,
          debits: null,
          phase: "uncertain",
          chain: "Bitcoin",
          tx_id: null,
        }}
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

it("shows recovered destination and exact debits for reconciliation", () => {
  render(
    <MemoryRouter>
      <SendPage
        client={fakeClient()}
        generation={2}
        onSent={vi.fn()}
        submission={{
          version: 2,
          phase: "uncertain",
          chain: "Bitcoin",
          tx_id: null,
          request: {
            asset: { chain: "Bitcoin", asset_id: null },
            destination: "tb1-recovered-destination",
            amount: { mode: "Exact", units: "1000" },
            fee_rate_sat_per_vbyte: 1,
          },
          debits: [
            { asset: { chain: "Bitcoin", asset_id: null }, units: "1100" },
          ],
        }}
      />
    </MemoryRouter>,
  );
  expect(screen.getByText("tb1-recovered-destination")).toBeInTheDocument();
  expect(screen.getByText(/0,00001100/)).toBeInTheDocument();
});
it("discards an old pending review when the unlocked generation changes", async () => {
  const c = fakeClient();
  let resolve!: (value: Awaited<ReturnType<typeof c.reviewSend>>) => void;
  vi.mocked(c.reviewSend).mockReturnValue(
    new Promise((r) => {
      resolve = r;
    }),
  );
  const view = render(
    <MemoryRouter>
      <SendPage client={c} generation={1} onSent={() => {}} />
    </MemoryRouter>,
  );
  fireEvent.change(screen.getByLabelText("Endereço de destino"), {
    target: { value: "tb1-old" },
  });
  fireEvent.change(screen.getByLabelText("Quantidade (BTC)"), {
    target: { value: "1" },
  });
  fireEvent.click(screen.getByText("Revisar envio"));
  view.rerender(
    <MemoryRouter>
      <SendPage client={c} generation={2} onSent={() => {}} />
    </MemoryRouter>,
  );
  resolve({
    id: "old",
    is_max: false,
    generation: 1,
    expires_at_ms: Date.now() + 60000,
    fee_sat: 1,
    debits: [],
    request: {
      asset: { chain: "Bitcoin", asset_id: null },
      destination: "tb1-old",
      amount: { mode: "Exact", units: "100000000" },
      fee_rate_sat_per_vbyte: 1,
    },
  });
  await waitFor(() =>
    expect(screen.getByLabelText("Endereço de destino")).toHaveValue(""),
  );
  expect(screen.queryByText("Confirmar envio")).not.toBeInTheDocument();
});
it("checks an uncertain result without submitting again", async () => {
  const c = fakeClient();
  vi.mocked(c.refresh).mockResolvedValue(undefined);
  const onSent = vi.fn();
  render(
    <MemoryRouter>
      <SendPage
        client={c}
        generation={1}
        onSent={onSent}
        submission={{
          version: 2,
          phase: "uncertain",
          chain: "Liquid",
          tx_id: null,
          request: null,
          debits: null,
        }}
      />
    </MemoryRouter>,
  );
  fireEvent.click(screen.getByRole("button", { name: "Atualizar histórico" }));
  await waitFor(() => expect(onSent).toHaveBeenCalledOnce());
  expect(c.refresh).toHaveBeenCalledOnce();
  expect(c.confirmSend).not.toHaveBeenCalled();
});
import { SendDraftContext } from "./send-draft";
it("restores the fee-recovery draft through catalog loading without restoring Max", async () => {
  const c = fakeClient();
  vi.mocked(c.approvedAssets).mockResolvedValue([
    {
      key: { chain: "Liquid", asset_id: "test" },
      ticker: "TEST",
      precision: 8,
      approved: true,
    },
  ]);
  render(
    <MemoryRouter>
      <SendDraftContext.Provider
        value={{
          draft: {
            selected: "Liquid:test",
            destination: "tlq-saved",
            amount: "0,12",
            rate: "2,5",
          },
          save: vi.fn(),
        }}
      >
        <SendPage client={c} generation={1} onSent={vi.fn()} />
      </SendDraftContext.Provider>
    </MemoryRouter>,
  );
  await screen.findByLabelText("Quantidade (TEST)");
  expect(screen.getByLabelText("Taxa da rede (sat/vB)")).toHaveValue("2,5");
  expect(screen.getByLabelText("Endereço de destino")).toHaveValue("tlq-saved");
  expect(screen.getByLabelText("Quantidade (TEST)")).toHaveValue("0,12");
  expect(screen.getByRole("checkbox")).not.toBeChecked();
});
