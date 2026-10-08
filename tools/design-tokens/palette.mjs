/** @typedef {{version: 1, light: Record<string, string | {ref: string}>, dark: Record<string, string | {ref: string}>}} Palette */
/** @typedef {{light: Record<string,string>, dark: Record<string,string>}} ResolvedPalette */
const isObject = value => value !== null && typeof value === 'object' && !Array.isArray(value);
/** @param {unknown} input @returns {Palette} */
export function validatePalette(input) {
  if (!isObject(input) || input.version !== 1 || !isObject(input.light) || !isObject(input.dark)) throw new Error('Expected version 1 light/dark palette');
  const keys = Object.keys(input.light).sort();
  if (!keys.length || JSON.stringify(keys) !== JSON.stringify(Object.keys(input.dark).sort())) throw new Error('Modes must have identical nonempty keys');
  for (const mode of ['light','dark']) for (const [key,value] of Object.entries(input[mode])) {
    if (!/^[a-z][a-zA-Z0-9]*$/.test(key)) throw new Error(`Invalid token name: ${key}`);
    if (typeof value === 'string' && /^#[\da-f]{6}([\da-f]{2})?$/i.test(value)) continue;
    if (isObject(value) && Object.keys(value).length === 1 && typeof value.ref === 'string') continue;
    throw new Error(`Invalid color or reference: ${mode}.${key}`);
  }
  return input;
}
/** @param {Palette} input @returns {ResolvedPalette} */
export function resolvePalette(input) {
  const palette = validatePalette(input);
  return Object.fromEntries(['light','dark'].map(mode => {
    const resolved = Object.create(null), visiting = new Set();
    const resolve = key => {
      if (Object.hasOwn(resolved,key)) return resolved[key];
      if (!Object.hasOwn(palette[mode],key)) throw new Error(`Missing reference: ${mode}.${key}`);
      if (visiting.has(key)) throw new Error(`Reference cycle: ${mode}.${key}`);
      visiting.add(key);
      const value = palette[mode][key];
      resolved[key] = typeof value === 'string' ? value.toUpperCase() : resolve(value.ref);
      visiting.delete(key);
      return resolved[key];
    };
    Object.keys(palette[mode]).sort().forEach(resolve);
    return [mode, resolved];
  }));
}
const entries = values => Object.entries(values).sort(([a],[b])=>a.localeCompare(b,'en'));
const kebab = name => name.replace(/[A-Z]/g, letter => `-${letter.toLowerCase()}`);
/** @param {ResolvedPalette} palette @returns {string} */
export function renderCss(palette) {
  const block = (selector,mode) => `${selector} {\n  color-scheme: ${mode};\n${entries(palette[mode]).map(([name,color]) => `  --app-${kebab(name)}: ${color};`).join('\n')}\n}\n`;
  return '/* Generated from packages/design-tokens/colors.json. Do not edit. */\n' +
    block(':root', 'light') + '\n@media (prefers-color-scheme: dark) {\n' + block('  :root:not([data-theme])','dark') + '}\n\n' +
    block(':root[data-theme="light"]','light') + '\n' + block(':root[data-theme="dark"]','dark');
}
/** @param {ResolvedPalette} palette @returns {string} */
export function renderDart(palette) {
  return "// Generated from packages/design-tokens/colors.json. Do not edit.\nimport 'package:flutter/material.dart';\n\n" + ['light','dark'].map(mode => {
    const fields = entries(palette[mode]).map(([name,color]) => {
      const rgb = color.slice(1,7), alpha = color.slice(7) || 'FF';
      return `  static const ${name} = Color(0x${alpha}${rgb});`;
    }).join('\n');
    return `abstract final class AppPalette${mode === 'light' ? 'Light' : 'Dark'} {\n${fields}\n}\n`;
  }).join('\n');
}
