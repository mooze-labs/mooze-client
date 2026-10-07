import { afterEach, it, expect, vi } from "vitest";
import {
  render,
  screen,
  fireEvent,
  waitFor,
  cleanup,
  act,
} from "@testing-library/react";
import { SetupPage } from "./setup-page";
import { fakeClient } from "../../testing/client";
const phrase =
  "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
const unlocked = { status: "unlocked", generation: 1, retry_after_ms: 0 };
afterEach(() => {
  cleanup();
  vi.useRealTimers();
});
function start(acceptTerms = true) {
  const client = fakeClient();
  vi.mocked(client.beginSetup).mockImplementation(async () => ({
    setup_id: "s",
    words: phrase.split(" "),
    challenge_indices: [0, 5, 11],
    expires_at_ms: Date.now() + 600_000,
  }));
  vi.mocked(client.sessionStatus).mockResolvedValue({
    status: "empty",
    generation: 0,
    retry_after_ms: 0,
  });
  const onSession = vi.fn();
  render(<SetupPage client={client} onSession={onSession} />);
  if (acceptTerms)
    fireEvent.click(screen.getByRole("checkbox", { name: /Li e aceito/ }));
  return { client, onSession };
}

async function backup() {
  fireEvent.click(screen.getByRole("button", { name: "Criar carteira" }));
  fireEvent.click(screen.getByRole("button", { name: "Gerar frase" }));
  await screen.findByRole("button", { name: "Revelar frase" });
  expect(screen.queryByText("about")).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Revelar frase" }));
  fireEvent.click(screen.getByRole("button", { name: "Anotei minha frase" }));
}
async function pinStep() {
  await backup();
  for (const [number, word] of [
    [1, "abandon"],
    [6, "abandon"],
    [12, "about"],
  ])
    fireEvent.change(screen.getByLabelText(`Palavra ${number}`), {
      target: { value: word },
    });
  fireEvent.click(screen.getByRole("button", { name: "Continuar" }));
}
function pin() {
  fireEvent.change(screen.getByLabelText("Criar PIN"), {
    target: { value: "123456" },
  });
  fireEvent.change(screen.getByLabelText("Confirmar PIN"), {
    target: { value: "123456" },
  });
}
it("allows reviewing the same phrase and blocks incorrect backup answers", async () => {
  const { client } = start();
  await backup();
  fireEvent.click(screen.getByRole("button", { name: "Rever minha frase" }));
  fireEvent.click(screen.getByRole("button", { name: "Revelar frase" }));
  expect(screen.getByText("about")).toBeVisible();
  expect(client.beginSetup).toHaveBeenCalledTimes(1);
  fireEvent.click(screen.getByRole("button", { name: "Anotei minha frase" }));
  for (const n of [1, 6, 12])
    fireEvent.change(screen.getByLabelText(`Palavra ${n}`), {
      target: { value: "wrong" },
    });
  fireEvent.click(screen.getByRole("button", { name: "Continuar" }));
  expect(screen.getByRole("alert")).toHaveTextContent("Confira");
  expect(screen.queryByLabelText("Criar PIN")).not.toBeInTheDocument();
});
it("validates recovery before requesting a PIN and preserves editable words", async () => {
  const { client, onSession } = start();
  client.validateRecoveryPhrase = vi
    .fn()
    .mockRejectedValueOnce({ code: "invalid_checksum" })
    .mockResolvedValue(undefined);
  vi.mocked(client.importWallet).mockResolvedValue(unlocked);
  fireEvent.click(screen.getByRole("button", { name: "Importar carteira" }));
  fireEvent.change(screen.getByLabelText("Frase de recuperação"), {
    target: { value: phrase.toUpperCase() },
  });
  fireEvent.click(screen.getByRole("button", { name: "Organizar palavras" }));
  expect(screen.getByLabelText("Palavra 12")).toHaveValue("about");
  fireEvent.click(screen.getByRole("button", { name: "Continuar" }));
  await screen.findByRole("alert");
  expect(screen.queryByLabelText("Criar PIN")).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Continuar" }));
  await screen.findByLabelText("Criar PIN");
  expect(client.validateRecoveryPhrase).toHaveBeenLastCalledWith(phrase);
  pin();
  fireEvent.click(screen.getByRole("button", { name: "Importar e continuar" }));
  await waitFor(() => expect(onSession).toHaveBeenCalledWith(unlocked));
  expect(client.importWallet).toHaveBeenCalledExactlyOnceWith(phrase, "123456");
});
it("retries failed creation without discarding the backed-up phrase", async () => {
  const { client, onSession } = start();
  vi.mocked(client.completeSetup)
    .mockRejectedValueOnce(new Error("storage"))
    .mockResolvedValue(unlocked);
  await pinStep();
  pin();
  fireEvent.click(screen.getByRole("button", { name: "Concluir criação" }));
  await screen.findByRole("alert");
  expect(screen.getByLabelText("Criar PIN")).toHaveValue("");
  pin();
  fireEvent.click(screen.getByRole("button", { name: "Concluir criação" }));
  await waitFor(() => expect(onSession).toHaveBeenCalledWith(unlocked));
  expect(client.beginSetup).toHaveBeenCalledTimes(1);
});
it("hands off a committed wallet to unlock after preparation fails", async () => {
  const { client, onSession } = start();
  vi.mocked(client.completeSetup).mockRejectedValue(new Error("connection"));
  const locked = { status: "locked", generation: 1, retry_after_ms: 0 };
  vi.mocked(client.sessionStatus).mockResolvedValue(locked);
  await pinStep();
  pin();
  fireEvent.click(screen.getByRole("button", { name: "Concluir criação" }));
  await waitFor(() => expect(onSession).toHaveBeenCalledWith(locked));
});
it("warns before the backend deadline and clears the expired phrase", async () => {
  vi.useFakeTimers({ shouldAdvanceTime: true });
  const { client } = start();
  await backup();
  await act(async () => {
    vi.advanceTimersByTime(481_000);
  });
  expect(screen.getByRole("status")).toHaveTextContent("expira");
  await act(async () => {
    vi.advanceTimersByTime(120_000);
  });
  expect(screen.queryByLabelText("Palavra 1")).not.toBeInTheDocument();
  expect(screen.getByRole("alert")).toHaveTextContent("expirou");
  expect(client.cancelSetup).toHaveBeenCalledWith("s");
});

it("blocks resubmission while the saved-wallet state is unknown", async () => {
  const { client } = start();
  vi.mocked(client.completeSetup).mockRejectedValue(new Error("storage"));
  vi.mocked(client.sessionStatus)
    .mockRejectedValueOnce(new Error("unavailable"))
    .mockResolvedValue({ status: "empty", generation: 0, retry_after_ms: 0 });
  await pinStep();
  pin();
  fireEvent.click(screen.getByRole("button", { name: "Concluir criação" }));
  await screen.findByRole("button", { name: "Verificar estado" });
  expect(screen.queryByLabelText("Criar PIN")).not.toBeInTheDocument();
  expect(
    screen.queryByRole("button", { name: "Cancelar criação" }),
  ).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Verificar estado" }));
  await screen.findByLabelText("Criar PIN");
  expect(client.completeSetup).toHaveBeenCalledTimes(1);
});
it("clears the backup on cancellation", async () => {
  const { client } = start();
  await backup();
  fireEvent.click(screen.getByRole("button", { name: "Cancelar criação" }));
  expect(screen.queryByLabelText("Palavra 1")).not.toBeInTheDocument();
  expect(client.cancelSetup).toHaveBeenCalledWith("s");
  expect(screen.getByRole("button", { name: "Criar carteira" })).toBeEnabled();
});
it("keeps keyboard focus when switching recovery editors", () => {
  start();
  fireEvent.click(screen.getByRole("button", { name: "Importar carteira" }));
  fireEvent.change(screen.getByLabelText("Frase de recuperação"), {
    target: { value: phrase },
  });
  fireEvent.click(screen.getByRole("button", { name: "Organizar palavras" }));
  expect(screen.getByLabelText("Palavra 1")).toHaveFocus();
  fireEvent.click(
    screen.getByRole("button", { name: "Editar frase completa" }),
  );
  expect(screen.getByLabelText("Frase de recuperação")).toHaveFocus();
  expect(screen.getByLabelText("Frase de recuperação")).toHaveValue(phrase);
});
it.each(["success", "failure"])(
  "does not expire a pending creation until its %s outcome is known",
  async (outcome) => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    const { client, onSession } = start();
    let resolve!: (session: typeof unlocked) => void;
    let reject!: (error: Error) => void;
    vi.mocked(client.completeSetup).mockImplementation(
      () =>
        new Promise((yes, no) => {
          resolve = yes;
          reject = no;
        }),
    );
    await pinStep();
    pin();
    fireEvent.click(screen.getByRole("button", { name: "Concluir criação" }));
    await act(async () => {
      vi.advanceTimersByTime(601_000);
    });
    expect(
      screen.getByRole("heading", { name: "Preparando sua carteira" }),
    ).toBeVisible();
    expect(client.cancelSetup).not.toHaveBeenCalled();
    await act(async () => {
      if (outcome === "success") resolve(unlocked);
      else reject(new Error("storage"));
    });
    if (outcome === "success") expect(onSession).toHaveBeenCalledWith(unlocked);
    else
      expect(
        screen.getByRole("heading", { name: "Sua criação expirou" }),
      ).toBeVisible();
    expect(client.beginSetup).toHaveBeenCalledTimes(1);
  },
);

it("requires explicit terms acceptance for both paths without accepting on dialog close", async () => {
  const { client } = start(false);
  const create = screen.getByRole("button", { name: "Criar carteira" });
  const importButton = screen.getByRole("button", {
    name: "Importar carteira",
  });
  expect(create).toBeDisabled();
  expect(importButton).toBeDisabled();
  fireEvent.click(
    screen.getByRole("button", { name: "Ler termos e condições" }),
  );
  const dialog = await screen.findByRole("dialog", {
    name: "Termos e condições — versão provisória",
  });
  expect(dialog).toHaveTextContent("Lorem ipsum");
  expect(dialog).toHaveAccessibleDescription(/não são os termos finais/);
  fireEvent.click(screen.getByRole("button", { name: "Fechar" }));
  await waitFor(() =>
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument(),
  );
  const checkbox = screen.getByRole("checkbox", { name: /Li e aceito/ });
  expect(checkbox).not.toBeChecked();
  expect(create).toBeDisabled();
  fireEvent.click(checkbox);
  expect(create).toBeEnabled();
  expect(importButton).toBeEnabled();
  fireEvent.click(importButton);
  expect(screen.getByLabelText("Frase de recuperação")).toBeVisible();
  fireEvent.click(screen.getByRole("button", { name: "Voltar" }));
  expect(screen.getByRole("checkbox", { name: /Li e aceito/ })).toBeChecked();
  fireEvent.click(screen.getByRole("checkbox", { name: /Li e aceito/ }));
  expect(screen.getByRole("button", { name: "Criar carteira" })).toBeDisabled();
  expect(
    screen.getByRole("button", { name: "Importar carteira" }),
  ).toBeDisabled();
  expect(client.beginSetup).not.toHaveBeenCalled();
});
