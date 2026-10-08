import {beforeEach,expect,it,vi} from 'vitest';
const native=vi.hoisted(()=>({isTauri:vi.fn(),setTheme:vi.fn()}));
vi.mock('@tauri-apps/api/core',()=>({isTauri:native.isTauri}));
vi.mock('@tauri-apps/api/window',()=>({getCurrentWindow:()=>({setTheme:native.setTheme})}));
import {setNativeTheme} from './native';
beforeEach(()=>{vi.resetAllMocks();native.isTauri.mockReturnValue(true);native.setTheme.mockResolvedValue(undefined);});
it.each([['light','light'],['dark','dark'],['system',null]] as const)('maps %s to native %s',async(preference,value)=>{await setNativeTheme(preference);expect(native.setTheme).toHaveBeenCalledWith(value);});
it('does not call native APIs in a browser',async()=>{native.isTauri.mockReturnValue(false);await setNativeTheme('dark');expect(native.setTheme).not.toHaveBeenCalled();});
it('exposes native rejection to the lifecycle adapter',async()=>{native.setTheme.mockRejectedValue(new Error('denied'));await expect(setNativeTheme('dark')).rejects.toThrow('denied');});
