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
  fireEvent.change(screen.getByLabelText("Criar PIN"), {
    target: { value: "123456" },
  });
  fireEvent.change(screen.getByLabelText("Confirmar PIN"), {
    target: { value: "654321" },
  });
  for (let i = 1; i <= 3; i++)
    fireEvent.change(screen.getByLabelText(`Palavra ${i}`), {
      target: { value: "test" },
    });
  fireEvent.click(screen.getByText("Concluir criação"));
  await waitFor(() =>
    expect(screen.getByRole("alert")).toHaveTextContent("não coincidem"),
  );
  expect(c.completeSetup).not.toHaveBeenCalled();
});
