/*
 * Lily Pad
 * https://polyfork.dev/asset/lily-pad-86edbb
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './lily-pad-86edbb.mjs';
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
 *   colorway   choice  'pond-green'   'pond-green' | 'deep-emerald' | 'spring-lime' | 'autumn-bronze'
 *   plate      color   '#93c46a'      any hex or THREE.Color
 *   rim        color   '#4c8140'      any hex or THREE.Color
 *   underside  color   '#3d6b34'      any hex or THREE.Color
 *   across     range   0.6            0.4 to 0.66
 *   notch      range   18             8 to 46
 *   cup        range   0.55           0 to 1
 *   wobble     range   1              0 to 1.6
 *
 * Every option is described in full at https://polyfork.dev/cdn/lily-pad-86edbb-params.json
 *
 * SPECS  398 triangles, 1 material, 0.6 x 0.04 x 0.59 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const DEG = Math.PI / 180;

export const COLORWAYS = {

  'pond-green':   { plate: 0x93C46A, rim: 0x4C8140, underside: 0x3D6B34 },

  'deep-emerald': { plate: 0x5F9A4B, rim: 0x2F4F2E, underside: 0x25402C },

  'spring-lime':  { plate: 0xB3D47F, rim: 0x6F8F3C, underside: 0x4C8140 },

  'autumn-bronze':{ plate: 0xC2A479, rim: 0x8C6A47, underside: 0x75563B },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'pond-green', label: 'Colorway',
    options: ['pond-green', 'deep-emerald', 'spring-lime', 'autumn-bronze'],
    describe: 'curated kit-coherent scheme setting the three zones at once, always plate lighter than rim lighter than underside so the dark ring stays readable. pond-green = the approved pad, a light leaf-green plate inside a mid-green rim; deep-emerald = every rung dropped for shaded deep water, a near-black rim around a mid plate, the highest-contrast scheme; spring-lime = new growth, the plate lifted to the palette\'s palest leaf green over an olive rim; autumn-bronze = late season, the whole leaf gone over to warm bronze and brown, the only non-green scheme',
  },
  plate: {
    type: 'color', default: '#93c46a', label: 'Plate',
    describe: 'albedo of the dished top surface inside the rim — the pad\'s largest mass and the colour a viewer reads from directly above. Keep it a clear value step LIGHTER than the rim or the ring that defines the pad\'s edge disappears',
  },
  rim: {
    type: 'color', default: '#4c8140', label: 'Rim lip',
    describe: 'albedo of the raised lip that runs the whole perimeter: its crest, its outer wall down to the widest point, its inner wall falling to the plate, and both cut cheeks of the notch. The dark ring that outlines the pad from above and the whole of the notch from any angle',
  },
  underside: {
    type: 'color', default: '#3d6b34', label: 'Underside',
    describe: 'albedo of the flat bottom face and the bevel that runs from it out to the pad\'s widest point — the darkest of the three zones. Seen only from a low or under-water camera, where it must read darker than the rim so the pad does not look like a slab of one colour',
  },
  across: {
    type: 'range', default: 0.6, min: 0.4, max: 0.66, label: 'Across', affects: 'geometry',
    describe: 'diameter of the pad in metres, its defining dimension. REBUILT, not scaled: the facet chord is held at a constant 0.088 m, so a bigger pad gains real facets around its rim (triangle count moves: 290 tris at 0.40 m, 398 at 0.60 m, 434 at 0.66 m) while every SECTION stays exactly put — the 0.038 m rim band, the 0.024 m underside bevel and the 0.039 m thickness are the same on a small pad and a large one. 0.40 = a young pad that reads as a leaf, 0.66 = a mature pad a frog could sit on, with a proportionally thinner-looking rim',
  },
  notch: {
    type: 'range', default: 18, min: 8, max: 46, label: 'Notch', affects: 'geometry',
    describe: 'angular width in degrees of the V cut out of the +Z edge at the waterline, apex at the pad\'s centre; the cheeks splay as they rise, so the mouth at the crest is about 10 degrees wider than this number. The rim lip is rebuilt ALONG both cheeks at every value, so from above the dark ring always turns inward and closes into a keyhole and no plate colour touches the cut. 8 = a tight slit, the pad nearly a closed disc; 18 = the approved notch, 0.086 m across the mouth at the waterline and 0.14 m at the crest; 46 = a wide open sinus that takes an eighth of the pad away and reads as a fat green Pac-Man from above',
  },
  cup: {
    type: 'range', default: 0.55, min: 0, max: 1, label: 'Cup', affects: 'geometry',
    describe: 'how strongly the rim lip lifts away from the plate, rebuilding the whole profile. 0 = a nearly flat pad, crest 0.030 m with only a 0.009 m dish and no rim ripple, reading as a leaf floating dead flat; 0.55 = the approved lip, crest 0.039 m over a 0.015 m dish; 1 = a pronounced curled lip, crest 0.046 m over a 0.019 m dish with the crest height rippling +/-0.0055 m around the pad, so the outline visibly undulates in the side view',
  },
  wobble: {
    type: 'range', default: 1, min: 0, max: 1.6, label: 'Wobble', affects: 'geometry',
    describe: 'multiplier on the organic irregularity of the outline: three cosine harmonics (3, 5 and 8 lobes) modulating the radius, always mirror-symmetric about the notch axis. 0 = a perfectly regular polygon disc, the machined-coin look; 1 = the approved pad, radius rippling +/-8.5%; 1.6 = a ragged storm-chewed leaf rippling +/-13.6% with clearly lobed edges. The overall width is renormalised at every value, so the pad is always exactly `across` metres wide',
  },
};

export const rig = {};
export const detach = [];

export const night = {};

const ZONE_KEYS = ['plate', 'rim', 'underside'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['pond-green'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? COLORWAYS['pond-green'][k]) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

function prep(geo, hex) {
  if (geo.index) geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function finish(list) {
  const merged = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  merged.clearGroups();
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const CHORD     = 0.088;
const RIM_W     = 0.038;
const RIM_LEAN  = 0.005;
const BEVEL     = 0.024;
const Y_EQ      = 0.012;
const CREST0    = 0.030;
const CREST_UP  = 0.016;
const DISH0     = 0.009;
const DISH_UP   = 0.010;
const RIPPLE    = 0.0055;
const WOB_AMP   = 0.072;
const VEIN      = 0.0045;
const CHEEK_LEAN = 2.2;
const CHEEK_RISE = 0.008;

const CHEEK_IN  = 9 * DEG;

const PLATE_R   = [0.94, 0.74, 0.55, 0.36, 0.17];
const PLATE_Y   = [0.0016, 0.0010, 0.0005, 0.0001, -0.0003];
const VEIN_T    = [0.25, 0.80, 1.0, 0.70, 0.20];

function wobbleAt(phi) {
  return 0.46 * Math.cos(3 * phi) + 0.34 * Math.cos(5 * phi) + 0.20 * Math.cos(8 * phi);
}

export function createAsset(o = {}) {
  const opts = o || {};
  const across = clamp(num(opts.across, 0.6), 0.4, 0.66);
  const notch  = clamp(num(opts.notch, 18), 8, 46) * DEG;
  const cup    = clamp(num(opts.cup, 0.55), 0, 1);
  const wob    = clamp(num(opts.wobble, 1), 0, 1.6);
  const C = zonesFor(opts.colorway || 'pond-green', opts);

  const R0 = across / 2;
  const half = notch / 2;
  const arc = Math.PI * 2 - notch;

  const N = clamp(2 * Math.round(arc * R0 / (2 * CHORD)), 8, 40);
  const dPhi = arc / N;

  const phi = [], rOut = [];
  let xMax = 0;
  for (let j = 0; j <= N; j++) {
    const p = half + j * dPhi;
    const r = R0 * (1 + WOB_AMP * wob * wobbleAt(p));
    phi.push(p); rOut.push(r);
    xMax = Math.max(xMax, Math.abs(r * Math.sin(p)));
  }
  const norm = R0 / xMax;
  for (let j = 0; j <= N; j++) rOut[j] *= norm;

  const crestMean = CREST0 + CREST_UP * cup;
  const dish      = DISH0 + DISH_UP * cup;
  const plateY    = crestMean - dish;

  const psi = [];
  for (let j = 0; j <= N; j++) psi.push(phi[j] + CHEEK_IN * (1 - 2 * j / N));

  const at = (a, r, y) => [r * Math.sin(a), y, r * Math.cos(a)];
  const lean = (j, y) => (j === 0 ? 1 : j === N ? -1 : 0) * CHEEK_LEAN * y;
  const PO = (r, y, j) => at(phi[j] + lean(j, y), r, y);
  const PI = (r, y, j) => at(psi[j] + lean(j, y), r, y);

  const bot = [], eq = [], crestO = [], crestI = [], pl = [[], [], [], [], []];
  for (let j = 0; j <= N; j++) {
    const rO = rOut[j];
    const rIn = rO - RIM_W;
    const yC = crestMean + cup * RIPPLE * Math.cos(4 * phi[j]);
    const vein = (j % 2 === 0 ? 1 : -1) * VEIN * 0.5;
    bot.push(PO(rO - BEVEL, 0, j));
    eq.push(PO(rO, Y_EQ, j));
    crestO.push(PO(rO - RIM_LEAN, yC, j));
    crestI.push(PI(rIn, yC - 0.0025, j));
    for (let k = 0; k < 5; k++) pl[k].push(PI(rIn * PLATE_R[k], plateY + PLATE_Y[k] + vein * VEIN_T[k], j));
  }
  const cBot = [0, 0, 0];
  const cTop = [0, plateY, 0];

  const band = (out, A, B) => { for (let j = 0; j < N; j++) quad(out, A[j], A[j + 1], B[j + 1], B[j]); };

  const under = [];
  for (let j = 0; j < N; j++) tri(under, cBot, bot[j + 1], bot[j]);
  band(under, bot, eq);

  const rim = [];
  band(rim, eq, crestO);
  band(rim, crestO, crestI);
  band(rim, crestI, pl[0]);

  const plate = [];
  for (let k = 0; k < 4; k++) band(plate, pl[k], pl[k + 1]);
  for (let j = 0; j < N; j++) tri(plate, pl[4][j], pl[4][j + 1], cTop);

  for (const j of [0, N]) {
    const rIn = rOut[j] - RIM_W;
    const vein = (j % 2 === 0 ? 1 : -1) * VEIN * 0.5;
    const inset = [crestI[j]], cut = [crestO[j]];
    for (let k = 0; k < 5; k++) {
      const r = rIn * PLATE_R[k];
      const y = plateY + PLATE_Y[k] + vein * VEIN_T[k] + CHEEK_RISE * PLATE_R[k];
      inset.push(pl[k][j]);
      cut.push(at(phi[j] + lean(j, y), r, y));
    }
    inset.push(cTop); cut.push(cTop);

    for (let i = 0; i < cut.length - 1; i++) {
      const a = cut[i], b = inset[i], c2 = inset[i + 1], d = cut[i + 1];
      if (i === cut.length - 2) {
        if (j === 0) tri(rim, a, b, c2); else tri(rim, a, c2, b);
      } else if (j === 0) quad(rim, a, b, c2, d);
      else quad(rim, a, d, c2, b);
    }

    const face = [cBot, bot[j], eq[j], crestO[j], ...cut.slice(1)];
    const M = face.length;
    const emit = (a, b, c) => { if (j === 0) tri(rim, a, b, c); else tri(rim, a, c, b); };
    for (let k = 2; k <= M - 2; k++) emit(face[1], face[k], face[k + 1]);
    emit(face[1], face[M - 1], face[0]);
  }
  const g = new THREE.Group();
  g.name = 'lily-pad';
  g.add(finish([
    { g: posGeo(under), c: C.underside },
    { g: posGeo(rim),   c: C.rim },
    { g: posGeo(plate), c: C.plate },
  ]));
  return g;
}

export default createAsset;
