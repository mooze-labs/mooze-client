import { it, expect, vi } from "vitest";
import {
  render,
  screen,
  fireEvent,
  waitFor,
  cleanup,
} from "@testing-library/react";
import { afterEach } from "vitest";
import { SessionScreen } from "./session-screen";
import { fakeClient } from "../../testing/client";
afterEach(cleanup);
it("rejects mismatched PIN before credentials cross the transport", () => {
  const c = fakeClient();
  render(
    <SessionScreen
      client={c}
      session={{ status: "empty", generation: 0, retry_after_ms: 0 }}
      onSession={vi.fn()}
    />,
  );
  fireEvent.change(screen.getByLabelText("Frase de recuperação"), {
    target: { value: "test phrase" },
  });
  fireEvent.change(screen.getByLabelText("Criar PIN"), {
    target: { value: "123456" },
  });
  fireEvent.change(screen.getByLabelText("Confirmar PIN"), {
    target: { value: "654321" },
  });
  fireEvent.click(screen.getByText("Importar e continuar"));
  expect(screen.getByRole("alert")).toHaveTextContent("não coincidem");
  expect(c.importWallet).not.toHaveBeenCalled();
});
it("clears secrets after a successful import", async () => {
  const c = fakeClient();
  vi.mocked(c.importWallet).mockResolvedValue({
    status: "unlocked",
    generation: 1,
    retry_after_ms: 0,
  });
  const done = vi.fn();
  render(
    <SessionScreen
      client={c}
      session={{ status: "empty", generation: 0, retry_after_ms: 0 }}
      onSession={done}
    />,
  );
  fireEvent.change(screen.getByLabelText("Frase de recuperação"), {
    target: { value: "test phrase" },
  });
  for (const label of ["Criar PIN", "Confirmar PIN"])
    fireEvent.change(screen.getByLabelText(label), {
      target: { value: "123456" },
    });
  fireEvent.click(screen.getByText("Importar e continuar"));
  await waitFor(() => expect(done).toHaveBeenCalled());
  expect(screen.getByLabelText("Frase de recuperação")).toHaveValue("");
  expect(screen.getByLabelText("Criar PIN")).toHaveValue("");
});
