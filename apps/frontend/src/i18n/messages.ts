import {createIntl,createIntlCache} from "react-intl";
import {usePreferences} from "./preferences";
import pt from "./pt-BR.json";
import en from "./en.json";
import es from "./es.json";
const cache=createIntlCache();
const catalogs={"pt-BR":pt,en,es};
export function translator(locale:keyof typeof catalogs){
 const intl=createIntl({locale,messages:catalogs[locale],onError:()=>{}},cache);
 return (message:string,values?:Record<string,string|number>)=>intl.formatMessage({id:message,defaultMessage:message},values);
}
export function useT(){return translator(usePreferences().preferences.locale);}
