import {createContext,useContext,useEffect,useState,type ReactNode} from "react";
import {useQuery} from "@tanstack/react-query";
import {IntlProvider} from "react-intl";
import {useWalletClient} from "../app/client-context";
import {useWalletSession} from "../app/session-provider";
export type Preferences={locale:"pt-BR"|"en"|"es";bitcoinUnit:"BTC"|"sat";privacy:boolean};
const defaults:Preferences={locale:"pt-BR",bitcoinUnit:"BTC",privacy:false};
export const PreferencesContext=createContext({preferences:defaults,save:async(_next:Preferences)=>{}});
export function usePreferences(){return useContext(PreferencesContext);}
export function PreferencesProvider({children}:{children:ReactNode}){
 const client=useWalletClient();const {session,current}=useWalletSession();
 const [preferences,setPreferences]=useState<Preferences>(()=>{try{const stored=JSON.parse(localStorage.getItem("mooze.display")??"null");return stored&&["pt-BR","en","es"].includes(stored.locale)&&["BTC","sat"].includes(stored.bitcoinUnit)&&typeof stored.privacy==="boolean"?stored:defaults;}catch{return defaults;}});
 const settings=useQuery({queryKey:["wallet",session?.generation,"settings"],enabled:session?.status==="unlocked",queryFn:()=>client.settings()});
 function apply(next:Preferences){setPreferences(next);localStorage.setItem("mooze.display",JSON.stringify(next));}
 useEffect(()=>{const value=settings.data;if(value)apply({locale:value.locale as Preferences["locale"],bitcoinUnit:value.bitcoin_unit as Preferences["bitcoinUnit"],privacy:value.privacy});},[settings.data]);
 async function save(next:Preferences){const generation=current.current?.generation;await client.saveDisplay(next.locale,next.bitcoinUnit,next.privacy);if(current.current?.status==="unlocked"&&generation===current.current.generation)apply(next);}
 return <PreferencesContext.Provider value={{preferences,save}}><IntlProvider locale={preferences.locale}>{children}</IntlProvider></PreferencesContext.Provider>;
}
