// Raw TeX on stdin, PNG at argv[2]. No browser or remote rendering service.
import fs from 'node:fs';
import {createRequire} from 'node:module';
import sharp from 'sharp';
const require = createRequire(import.meta.url);
global.MathJax = {
  loader: {paths: {mathjax: 'mathjax'}, load: ['adaptors/liteDOM'], require},
  svg: {fontCache: 'none'},
  tex: {formatError: (_jax, error) => { throw error; }},
};
try {
  require('mathjax/tex-svg.js');
  await MathJax.startup.promise;
  const node = await MathJax.tex2svgPromise(fs.readFileSync(0, 'utf8'), {
    display: process.argv[3] !== 'inline', em: 32, ex: 16, containerWidth: 1600,
  });
  const adaptor = MathJax.startup.adaptor;
  const svg = adaptor.tags(node, 'svg')[0];
  // librsvg has no surrounding HTML font context; give it explicit pixels.
  for (const name of ['width', 'height']) {
    const value = adaptor.getAttribute(svg, name);
    if (value.endsWith('ex')) adaptor.setAttribute(svg, name, `${parseFloat(value) * 16}px`);
  }
  adaptor.setAttribute(svg, 'color', 'black');
  await sharp(Buffer.from(adaptor.serializeXML(svg)))
    .flatten({background: 'white'})
    .extend({top: 24, bottom: 24, left: 24, right: 24, background: 'white'})
    .png().toFile(process.argv[2]);
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  MathJax.done?.();
}
