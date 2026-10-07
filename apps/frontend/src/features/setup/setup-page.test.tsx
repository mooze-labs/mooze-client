import { afterEach, it, expect, vi } from "vitest";
import {
  render,
  screen,
  fireEvent,
  waitFor,
  cleanup,
} from "@testing-library/react";
import { SetupPage } from "./setup-page";
import { fakeClient } from "../../testing/client";
afterEach(cleanup);
it("requires a backup check before creating the wallet", async () => {
  const c = fakeClient();
  vi.mocked(c.beginSetup).mockResolvedValue({
    setup_id: "s",
    words: ["abandon", "ability", "able"],
    challenge_indices: [0, 1, 2],
  });
  render(<SetupPage client={c} onSession={vi.fn()} />);
  fireEvent.click(screen.getByText("Criar carteira"));
  await screen.findByText("abandon");
  expect(c.completeSetup).not.toHaveBeenCalled();
  fireEvent.click(screen.getByText("Anotei minha frase"));
  expect(screen.queryByText("abandon")).not.toBeInTheDocument();
  expect(screen.queryByLabelText("Criar PIN")).not.toBeInTheDocument();
  for (let i = 1; i <= 3; i++)
    fireEvent.change(screen.getByLabelText(`Palavra ${i}`), {
      target: { value: "wrong" },
    });
  fireEvent.click(screen.getByText("Continuar"));
  expect(screen.queryByLabelText("Criar PIN")).not.toBeInTheDocument();
  for (const [i, word] of ["abandon", "ability", "able"].entries())
    fireEvent.change(screen.getByLabelText(`Palavra ${i + 1}`), {
      target: { value: word },
    });
  fireEvent.click(screen.getByText("Continuar"));
  expect(screen.queryByLabelText("Palavra 1")).not.toBeInTheDocument();
  expect(
    screen.getByRole("heading", { name: "Proteja sua carteira" }),
  ).toHaveFocus();
  fireEvent.change(screen.getByLabelText("Criar PIN"), {
    target: { value: "123456" },
  });
  fireEvent.change(screen.getByLabelText("Confirmar PIN"), {
    target: { value: "654321" },
  });
  fireEvent.click(screen.getByText("Concluir criação"));
  await waitFor(() =>
    expect(screen.getByRole("alert")).toHaveTextContent("não coincidem"),
  );
  expect(c.completeSetup).not.toHaveBeenCalled();
  vi.mocked(c.completeSetup).mockResolvedValue({
    status: "unlocked",
    generation: 1,
    retry_after_ms: 0,
  });
  fireEvent.change(screen.getByLabelText("Confirmar PIN"), {
    target: { value: "123456" },
  });
  fireEvent.click(screen.getByText("Concluir criação"));
  await waitFor(() =>
    expect(c.completeSetup).toHaveBeenCalledExactlyOnceWith(
      "s",
      ["abandon", "ability", "able"],
      "123456",
    ),
  );
});
