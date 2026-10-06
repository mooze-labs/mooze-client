import {afterEach,expect,it,vi} from "vitest";
import {cleanup,fireEvent,render,screen,waitFor} from "@testing-library/react";
import {WalletClientProvider} from "../../app/client-context";
import {fakeClient} from "../../testing/client";
import {RemoveWalletDialog} from "./remove-wallet-dialog";
afterEach(cleanup);
it("requires recovery acknowledgment and fresh PIN before removing local data",async()=>{
 const client=fakeClient();vi.mocked(client.removeWallet).mockRejectedValue({message:"storage failure"});
 render(<WalletClientProvider client={client}><RemoveWalletDialog/></WalletClientProvider>);
 fireEvent.click(screen.getByRole("button",{name:"Remover carteira local"}));
 const remove=await screen.findByRole("button",{name:"Remover dados locais"});
 expect(remove).toBeDisabled();
 fireEvent.change(screen.getByLabelText("Confirme seu PIN"),{target:{value:"123456"}});
 expect(remove).toBeDisabled();
 fireEvent.click(screen.getByRole("checkbox"));fireEvent.click(remove);
 await waitFor(()=>expect(client.removeWallet).toHaveBeenCalledExactlyOnceWith("123456"));
 expect(await screen.findByRole("alert")).toHaveTextContent("storage failure");
 expect(screen.getByLabelText("Confirme seu PIN")).toHaveValue("");
});
