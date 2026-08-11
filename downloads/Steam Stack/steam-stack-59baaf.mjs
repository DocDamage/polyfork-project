/*
 * Steam Stack
 * https://polyfork.dev/asset/steam-stack-59baaf
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './steam-stack-59baaf.mjs';
 *   scene.add(createAsset());
 *
 * The bare "three" specifiers below resolve through any bundler, or through
 * an importmap in your page:
 *
 *   { "imports": { "three": "https://unpkg.com/three@0.180.0/build/three.module.js",
 *                  "three/addons/": "https://unpkg.com/three@0.180.0/examples/jsm/" } }
 *
 * Browsers refuse to load ES modules from file:// URLs, so a page of your own
 * that imports this file has to be served over http:  python3 -m http.server
 *
 * The index.html in this asset's .zip download sidesteps that and opens with
 * a double-click. The store page above has the same snippet for Unity, Godot,
 * Blender and GLB.
 *
 * OPTIONS  createAsset({ ... })
 *
 *   colorway  choice  'taxi-yellow'  'taxi-yellow' | 'con-ed-red' | 'weathered-steel' | 'night-shift'
 *   stripe    color   '#e8a825'      any hex or THREE.Color
 *   band      color   '#ece5d3'      any hex or THREE.Color
 *   bore      color   '#211f1d'      any hex or THREE.Color
 *   girth     range   1              0.72 to 1.35
 *   taper     range   0.555          0.4 to 0.85
 *   sides     range   8              6 to 12
 *
 * Every option is described in full at https://polyfork.dev/cdn/steam-stack-59baaf-params.json
 *
 * SPECS  256 triangles, 1 material, 0.74 x 3 x 0.74 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {

  'taxi-yellow':     { stripe: 0xe8a825, band: 0xece5d3, bore: 0x211f1d },

  'con-ed-red':      { stripe: 0xc7504d, band: 0xece5d3, bore: 0x211f1d },

  'weathered-steel': { stripe: 0x7b8b8f, band: 0xcfc6b9, bore: 0x211f1d },

  'night-shift':     { stripe: 0x564e4a, band: 0xcfc6b9, bore: 0x211f1d },
};
export const presets = COLORWAYS;

export const params = {
  colorway: { type: 'choice', default: 'taxi-yellow', label: 'Colorway',
              options: ['taxi-yellow', 'con-ed-red', 'weathered-steel', 'night-shift'],
              describe: 'curated scheme, sets every zone albedo at once: taxi-yellow is the approved yellow-on-cream candy stripe, con-ed-red swaps the helix to brick red on the same cream, weathered-steel strips the hazard paint back to grey-blue zinc on warm stone with grey reveals, night-shift is dark bitumen bands on pale stone with the rim lip left taxi yellow' },
  stripe: { type: 'color', default: '#e8a825', label: 'Stripe',
            describe: 'albedo of the helical bands that carry the colour — about five of them wrap the shaft — and of the flared rim lip and mouth annulus at the top, which are the same paint on the same steel and so recolour with it. The loudest hue on the asset and the thing that identifies it at distance' },
  band:   { type: 'color', default: '#ece5d3', label: 'Ground band',
            describe: 'albedo of the alternating bands between the stripes; on the approved stack a warm cream, and it should stay clearly lighter than the stripe or the helix stops reading at thumbnail size' },
  bore:   { type: 'color', default: '#211f1d', label: 'Bore',
            describe: 'albedo of the throat wall and floor inside the mouth at the top — near black, soot; this is the darkest value on the asset and the only one seen from directly above' },
  girth:  { type: 'range', default: 1.0, min: 0.72, max: 1.35, label: 'Girth', affects: 'geometry',
            describe: 'base width at the fixed 3 m height, so this is the slenderness of the whole stack and the taper follows it. 0.72 is a lean 0.58 m flue that reads as a pipe, 1.0 the approved 0.80 m stack, 1.35 a fat 1.08 m chimney that reads as masonry. The helix pitch is fixed, so a fatter stack also wraps its stripes at a visibly shallower angle. Exactly triangle-neutral, and every value stays well inside one 4 m grid cell' },
  taper:  { type: 'range', default: 0.555, min: 0.40, max: 0.85, label: 'Taper', affects: 'geometry',
            describe: 'top radius as a fraction of the base radius, at a fixed height and base. 0.40 is a sharp cone narrowing to a 0.30 m mouth, 0.555 the approved profile, 0.85 an almost-straight 0.63 m column with only a hint of lean. Exactly triangle-neutral — it moves vertices, it never adds them. The mouth and rim lip follow the top radius' },
  sides:  { type: 'range', default: 8, min: 6, max: 12, label: 'Facets', affects: 'geometry',
            describe: 'how many flat faces the shaft is turned from, which sets how faceted or how round the stack reads. 6 is a chunky hexagonal post with wide planes and a visibly polygonal mouth, 8 the approved octagon, 12 a near-cylindrical flue whose arrises almost disappear. Values are whole numbers. The helix always closes on itself at any facet count, and the widest value still sits far inside one 4 m grid cell' },
};

export const rig = {};
export const detach = [];

export const night = {};

const H0        = 3.00;
const R_BASE    = 0.40;
const COLLAR_H  = 0.095;

const COLLAR_R  = 0.045;
const WALL_T    = 0.010;

const BORE_D    = 0.45;
const HS        = 0.285;
const TURNS     = 6;

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function prep(geo, hex) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function clipHalf(poly, f) {
  const out = [];
  const E = 1e-12;
  for (let i = 0; i < poly.length; i++) {
    const a = poly[i], b = poly[(i + 1) % poly.length];
    const fa = f(a), fb = f(b);
    if (fa >= -E) out.push(a);
    if ((fa > E && fb < -E) || (fa < -E && fb > E)) {
      const u = fa / (fa - fb);
      out.push([a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u]);
    }
  }
  return out;
}
function area2(poly) {
  let a = 0;
  for (let i = 0; i < poly.length; i++) {
    const p = poly[i], q = poly[(i + 1) % poly.length];
    a += p[0] * q[1] - q[0] * p[1];
  }
  return a / 2;
}

function resolve(opts) {
  const out = {};
  for (const k in params) out[k] = params[k].default;
  const way = COLORWAYS[opts.colorway] || COLORWAYS[out.colorway];
  for (const k in way) out[k] = way[k];
  for (const k in opts) if (opts[k] !== undefined && k in params) out[k] = opts[k];
  return out;
}

export function createAsset(opts = {}) {
  const P = resolve(opts);

  const H      = H0;
  const rBase  = R_BASE * P.girth;
  const rTop   = rBase * P.taper;
  const yShaft = H - COLLAR_H;
  const SIDES  = Math.max(6, Math.min(12, Math.round(P.sides)));
  const step   = (Math.PI * 2) / SIDES;

  const radAt  = (y) => rBase + (rTop - rBase) * (y / H);

  const C = { stripe: P.stripe, band: P.band, bore: P.bore };
  const buckets = { stripe: [], band: [], bore: [] };
  const tri  = (z, a, b, c) => buckets[z].push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
  const quad = (z, a, b, c, d) => { tri(z, a, b, c); tri(z, a, c, d); };
  const fan  = (z, v) => { for (let i = 1; i < v.length - 1; i++) tri(z, v[0], v[i], v[i + 1]); };

  const ring = (y, r) => {
    const pts = [];
    for (let k = 0; k < SIDES; k++) {
      const a = (k + 0.5) * step;
      pts.push([Math.sin(a) * r, y, Math.cos(a) * r]);
    }
    return pts;
  };

  function facetFrame(j) {
    const a0 = (j - 0.5) * step, a1 = (j + 0.5) * step;
    const d0 = [Math.sin(a0), Math.cos(a0)], d1 = [Math.sin(a1), Math.cos(a1)];

    const at = (t, y) => {
      const r = radAt(y);
      return [((1 - t) * d0[0] + t * d1[0]) * r, y, ((1 - t) * d0[1] + t * d1[1]) * r];
    };

    const sAt = (p) => p[1] / HS - ((a0 + p[0] * step) / (Math.PI * 2)) * TURNS;
    return { at, sAt };
  }

  function stripeRect(F, t0, t1, y0, y1) {
    if (t1 - t0 < 1e-9 || y1 - y0 < 1e-9) return;
    const rect = [[t0, y0], [t1, y0], [t1, y1], [t0, y1]];
    let lo = Infinity, hi = -Infinity;
    for (const p of rect) { const s = F.sAt(p); if (s < lo) lo = s; if (s > hi) hi = s; }
    for (let k = Math.floor(lo); k <= Math.floor(hi); k++) {
      let poly = clipHalf(rect, (p) => F.sAt(p) - k);
      if (poly.length < 3) continue;
      poly = clipHalf(poly, (p) => (k + 1) - F.sAt(p));
      if (poly.length < 3 || Math.abs(area2(poly)) < 1e-9) continue;
      const zone = (((k % 2) + 2) % 2) === 0 ? 'stripe' : 'band';
      fan(zone, poly.map((p) => F.at(p[0], p[1])));
    }
  }

  for (let j = 0; j < SIDES; j++) stripeRect(facetFrame(j), 0, 1, 0, yShaft);

  const rLipBot = radAt(yShaft);
  const rLipTop = radAt(H) + COLLAR_R;
  const rBore   = radAt(H) - WALL_T;
  const lipLo = ring(yShaft, rLipBot), lipHi = ring(H, rLipTop);
  const mouth = ring(H, rBore), boreLo = ring(H - BORE_D, rBore);
  const boreC = [0, H - BORE_D, 0];

  for (let k = 0; k < SIDES; k++) {
    const m = (k + 1) % SIDES;
    quad('stripe', lipLo[k], lipLo[m], lipHi[m], lipHi[k]);
    quad('stripe', lipHi[k], lipHi[m], mouth[m], mouth[k]);
    quad('bore', boreLo[k], mouth[k], mouth[m], boreLo[m]);
    tri('bore',  boreC, boreLo[k], boreLo[m]);
  }

  const base = ring(0, rBase), baseC = [0, 0, 0];
  for (let k = 0; k < SIDES; k++) tri('band', baseC, base[(k + 1) % SIDES], base[k]);

  const geos = [];
  for (const z in buckets) if (buckets[z].length) geos.push(prep(posGeo(buckets[z]), C[z]));
  const merged = mergeGeometries(geos);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'stack';

  const g = new THREE.Group();
  g.name = 'street-steam-stack';
  g.add(mesh);
  return g;
}

export default createAsset;
