import { afterEach, expect, it, vi } from "vitest";
import { act, cleanup, render, screen } from "@testing-library/react";
import { PixPayment } from "./pix-payment";
import type { PixDepositViewDto } from "../../core/desktop.generated";
afterEach(() => {
  cleanup();
  vi.useRealTimers();
});
const deposit: PixDepositViewDto = {
  deposit_id: "d",
  pix_key: "payment-code",
  asset_id: "depix",
  amount_in_cents: "1234",
  status: "Pending",
  created_at_ms: 0,
  expires_at_ms: 10000,
  blockchain_txid: null,
  asset_amount: null,
};
it("hides an expired payment code without claiming payment or settlement", () => {
  vi.useFakeTimers();
  vi.setSystemTime(10001);
  render(<PixPayment deposit={deposit} />);
  expect(
    screen.getByRole("heading", { name: "QR code expirado" }),
  ).toBeInTheDocument();
  expect(
    screen.queryByRole("button", { name: "Copiar código Pix" }),
  ).not.toBeInTheDocument();
  expect(screen.queryByText("Ativos recebidos")).not.toBeInTheDocument();
});
it("keeps paid deposits processing even after the QR expiry", () => {
  vi.useFakeTimers();
  vi.setSystemTime(10001);
  render(<PixPayment deposit={{ ...deposit, status: "Paid" }} />);
  expect(
    screen.getByRole("heading", { name: "Pagamento em processamento" }),
  ).toBeInTheDocument();
  expect(screen.queryByText("QR code expirado")).not.toBeInTheDocument();
  expect(screen.queryByText("Ativos recebidos")).not.toBeInTheDocument();
});

it("removes the copy action when an open QR expires", () => {
  vi.useFakeTimers();
  vi.setSystemTime(9000);
  render(<PixPayment deposit={deposit} />);
  expect(
    screen.getByRole("button", { name: "Copiar código Pix" }),
  ).toBeInTheDocument();
  act(() => {
    vi.advanceTimersByTime(1000);
  });
  expect(
    screen.queryByRole("button", { name: "Copiar código Pix" }),
  ).not.toBeInTheDocument();
  expect(
    screen.getByRole("heading", { name: "QR code expirado" }),
  ).toBeInTheDocument();
});
