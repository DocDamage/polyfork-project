/*
 * Fabric Awning
 * https://polyfork.dev/asset/fabric-awning-4d6acc
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './fabric-awning-4d6acc.mjs';
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
 *   colorway     choice  'sakura-red'   'sakura-red' | 'matcha-cream' | 'indigo-linen' | 'saffron-canvas'
 *   stripeA      color   '#B5462F'      any hex or THREE.Color
 *   stripeB      color   '#D9CFBC'      any hex or THREE.Color
 *   frame        color   '#3C4145'      any hex or THREE.Color
 *   bracket      color   '#6B7278'      any hex or THREE.Color
 *   stripePairs  range   7              4 to 10
 *   projection   range   1.2            0.9 to 1.6
 *   hem          choice  'scalloped'    'scalloped' | 'pointed' | 'straight'
 *
 * Every option is described in full at https://polyfork.dev/cdn/fabric-awning-4d6acc-params.json
 *
 * SPECS  470 triangles, 1 material, 4 x 1.33 x 1.2 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const params = {
  colorway: {
    type: 'choice', default: 'sakura-red', label: 'Colorway',
    options: ['sakura-red', 'matcha-cream', 'indigo-linen', 'saffron-canvas'],
    describe: 'curated two-tone canvas scheme plus its ironmongery. sakura-red is the '
            + 'approved default (rust red against warm cream on dark slate); '
            + 'matcha-cream is a deep green and off-white shop awning; indigo-linen is '
            + 'a muted blue-grey and pale linen; saffron-canvas is a hot orange and '
            + 'stone pair for a food stall. The frame greys shift with each.',
  },
  stripeA: {
    type: 'color', default: '#B5462F', label: 'Dark stripe',
    describe: 'albedo of the dark canvas bands on the sloped top, the front hem and the '
            + 'scallop lobes above them. The band count is odd, so this colour also owns '
            + 'both end caps and reads as the awning\'s dominant hue (~45% of the tris).',
  },
  stripeB: {
    type: 'color', default: '#D9CFBC', label: 'Pale stripe',
    describe: 'albedo of the pale canvas bands alternating with the dark ones. Keep a '
            + 'wide value gap from stripeA or the stripes fuse into one flat sheet at '
            + 'street distance; near-parity is the one setting that kills this asset.',
  },
  frame: {
    type: 'color', default: '#3C4145', label: 'Header board',
    describe: 'albedo of the slate mounting board at the wall — the bar standing proud '
            + 'above the ridge and skirting below the soffit. Darkest zone on the part; '
            + 'it is what caps the top of the slope with a crisp line.',
  },
  bracket: {
    type: 'color', default: '#6B7278', label: 'Brackets',
    describe: 'albedo of the two diagonal knee brackets and their wall plates. Keep it a '
            + 'clear step LIGHTER than the header board or the underside reads as one '
            + 'dark smear from below.',
  },
  stripePairs: {
    type: 'range', default: 7, min: 4, max: 10, step: 1, affects: 'geometry',
    label: 'Stripe pairs',
    describe: 'how many PALE bands the canvas carries; the awning builds 2N+1 bands in '
            + 'total so both ends finish dark and the pattern mirrors. 4 gives 9 broad '
            + '0.44 m bands with big deep scallops; 10 gives 21 narrow 0.19 m bands with '
            + 'a fine ripple of small lobes. One scallop lobe per band always, so the hem '
            + 'is rebuilt with the stripes and the triangle count moves with the knob.',
  },
  projection: {
    type: 'range', default: 1.20, min: 0.90, max: 1.60, affects: 'geometry',
    label: 'Projection',
    describe: 'how far the awning reaches out from the wall, in metres, measured back to '
            + 'front. The 34-degree pitch is held, so a deeper awning is also a taller '
            + 'one: 0.90 is a tight shade hood barely past the shopfront, 1.60 is a full '
            + 'pavement canopy half a metre taller with much longer brackets. Width stays '
            + 'exactly 4 m at every value so clones still chain. Nothing repeats along '
            + 'this axis (the canopy is one unbroken plane), so it rebuilds proportions '
            + 'rather than adding parts and the triangle count is unchanged.',
  },
  hem: {
    type: 'choice', default: 'scalloped', label: 'Hem shape', affects: 'geometry',
    options: ['scalloped', 'pointed', 'straight'],
    describe: 'the bottom edge of the front valance. scalloped is the reference: one '
            + 'half-circle lobe per band. pointed dags it into triangular pennants of the '
            + 'same depth. straight cuts a plain level hem just over half as deep, for a '
            + 'plainer market awning. Only scalloped and pointed break the bottom line of '
            + 'the silhouette.',
  },
};
for (const k of Object.keys(params)) if (!params[k].affects) params[k].affects = 'colors';

const COLORWAYS = {

  'sakura-red':     { stripeA: '#B5462F', stripeB: '#D9CFBC', frame: '#3C4145', bracket: '#6B7278' },
  'matcha-cream':   { stripeA: '#2F6B4F', stripeB: '#F2EFE7', frame: '#2E3134', bracket: '#8A9197' },
  'indigo-linen':   { stripeA: '#5B6E8C', stripeB: '#E4E2DC', frame: '#2E3134', bracket: '#A9AFB4' },
  'saffron-canvas': { stripeA: '#E8853A', stripeB: '#D8D2C4', frame: '#4E5459', bracket: '#8A9197' },
};
export const presets = COLORWAYS;

function resolve(user = {}) {
  const p = {};
  for (const [k, spec] of Object.entries(params)) p[k] = spec.default;
  Object.assign(p, COLORWAYS[user.colorway ?? p.colorway] ?? {});
  for (const k of Object.keys(params)) if (user[k] !== undefined) p[k] = user[k];
  const hex = (s) => (typeof s === 'string' ? parseInt(s.replace('#', ''), 16) : s);
  const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, Number(v)));
  const pairs = Math.round(clamp(p.stripePairs, 4, 10));
  return {
    C: { A: hex(p.stripeA), B: hex(p.stripeB), F: hex(p.frame), K: hex(p.bracket) },
    N: pairs * 2 + 1,
    proj: clamp(p.projection, 0.90, 1.60),
    hem: ['scalloped', 'pointed', 'straight'].includes(p.hem) ? p.hem : 'scalloped',
  };
}

const W = 4.00, HW = W / 2;
const PITCH = 34 * Math.PI / 180;
const SLOPE = Math.tan(PITCH);
const BOARD_T = 0.10;
const BOARD_LIP = 0.07;
const BOARD_SKIRT = 0.10;
const BOARD_CH = 0.030;
const TV = 0.14;
const HEM_T = 0.10;
const CH = 0.035;
const BED = 0.03;

const SOF_REF = 0.4433, PROJ_REF = 1.20;
const LOBE_SEG = 4;
const BR_X = 1.50;
const BR_W = 0.09, BR_H = 0.10;
const PL_W = 0.18, PL_H = 0.24, PL_T = 0.05;

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
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

function wall(out, p, q, x0, x1) {
  quad(out, [x0, p[1], p[0]], [x1, p[1], p[0]], [x1, q[1], q[0]], [x0, q[1], q[0]]);
}

function cap(out, poly, x, sign) {
  const contour = poly.map((p) => new THREE.Vector2(p[0], p[1]));
  for (const f of THREE.ShapeUtils.triangulateShape(contour, [])) {
    let [a, b, c] = f.map((i) => poly[i]);
    const area = (b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1]);
    if (area < 0) { const t = b; b = c; c = t; }
    const A = [x, a[1], a[0]], B = [x, b[1], b[0]], C = [x, c[1], c[0]];
    if (sign > 0) tri(out, C, B, A); else tri(out, A, B, C);
  }
}

function hemProfile(hem, x0, x1, r, cusp) {
  const xc = (x0 + x1) / 2;
  if (hem === 'straight') { const y = cusp - 0.55 * r; return [[x0, y], [x1, y]]; }
  if (hem === 'pointed') return [[x0, cusp], [xc, cusp - r], [x1, cusp]];
  const p = [];
  for (let k = 0; k <= LOBE_SEG; k++) {
    const t = Math.PI * (1 + k / LOBE_SEG);
    p.push([xc + r * Math.cos(t), cusp + r * Math.sin(t)]);
  }
  return p;
}

export function createAsset(userParams = {}) {
  const { C, N, proj, hem } = resolve(userParams);

  const ZF = proj / 2;
  const ZW = -proj / 2;
  const ZBK = ZW + BOARD_T;
  const ZH = ZF - HEM_T;
  const ZFAB = ZBK - BED;

  const SOF = SOF_REF * (proj / PROJ_REF);
  const ySoffit = (z) => SOF + (ZH - z) * SLOPE;
  const yTop = (z) => ySoffit(z) + TV;

  const sw = W / N, r = sw / 2;

  const cusp = SOF - 0.15 * r;
  const yTopF = yTop(ZF);
  const BT = yTop(ZBK) + BOARD_LIP;
  const BB = ySoffit(ZBK) - BOARD_SKIRT;

  const buf = { [C.A]: [], [C.B]: [], [C.F]: [], [C.K]: [] };

  const zNose = ZF - CH;
  let hemEndL = cusp, hemEndR = cusp;

  const xs = [];
  for (let i = 0; i <= N; i++) xs.push(i === N ? HW : -HW + i * sw);

  for (let i = 0; i < N; i++) {
    const x0 = xs[i], x1 = xs[i + 1], xc = (x0 + x1) / 2;
    const col = buf[i % 2 === 0 ? C.A : C.B];
    const P = hemProfile(hem, x0, x1, r, cusp);
    if (i === 0) hemEndL = P[0][1];
    if (i === N - 1) hemEndR = P[P.length - 1][1];

    wall(col, [ZFAB, ySoffit(ZFAB)], [ZH, ySoffit(ZH)], x0, x1);
    wall(col, [ZH, ySoffit(ZH)], [ZH, cusp], x0, x1);
    wall(col, [ZF, cusp], [ZF, yTopF - CH], x0, x1);
    wall(col, [ZF, yTopF - CH], [zNose, yTop(zNose)], x0, x1);
    wall(col, [zNose, yTop(zNose)], [ZFAB, yTop(ZFAB)], x0, x1);

    const poly = [];
    if (P[0][1] < cusp - 1e-9) poly.push([x0, cusp]);
    for (const q of P) poly.push(q);
    if (P[P.length - 1][1] < cusp - 1e-9) poly.push([x1, cusp]);
    const Cf = [xc, cusp];
    for (let k = 0; k + 1 < poly.length; k++) {
      const a = poly[k], b = poly[k + 1];

      tri(col, [Cf[0], Cf[1], ZF], [a[0], a[1], ZF], [b[0], b[1], ZF]);
      tri(col, [Cf[0], Cf[1], ZH], [b[0], b[1], ZH], [a[0], a[1], ZH]);
    }
    for (let k = 0; k + 1 < P.length; k++) {
      const a = P[k], b = P[k + 1];
      quad(col, [a[0], a[1], ZF], [a[0], a[1], ZH], [b[0], b[1], ZH], [b[0], b[1], ZF]);
    }
  }

  for (const s of [-1, 1]) {
    const hy = s < 0 ? hemEndL : hemEndR;
    cap(buf[C.A], [
      [ZBK, ySoffit(ZBK)], [ZH, ySoffit(ZH)], [ZH, hy], [ZF, hy],
      [ZF, yTopF - CH], [zNose, yTop(zNose)], [ZBK, yTop(ZBK)],
    ], s * HW, s);
  }

  {
    const B = [
      [ZW, BB],
      [ZBK - BOARD_CH, BB],
      [ZBK, BB + BOARD_CH],
      [ZBK, ySoffit(ZBK)],
      [ZBK, yTop(ZBK)],
      [ZBK, BT - BOARD_CH],
      [ZBK - BOARD_CH, BT],
      [ZW, BT],
    ];
    const col = buf[C.F];
    for (const [a, b] of [[0, 1], [1, 2], [2, 3], [4, 5], [5, 6], [6, 7], [7, 0]]) {
      wall(col, B[a], B[b], -HW, HW);
    }
    for (const s of [-1, 1]) cap(col, B, s * HW, s);
  }

  {
    const zK1 = ZH - 0.06;
    const yK1 = ySoffit(zK1) + 0.035;
    const zK0 = ZW + 0.01, yK0 = 0.02 + BR_H;
    const col = buf[C.K];
    for (const sx of [-1, 1]) {
      const x0 = sx * BR_X - BR_W / 2, x1 = sx * BR_X + BR_W / 2;
      const K = [
        [zK0, yK0 - BR_H], [zK1, yK1 - BR_H], [zK1, yK1], [zK0, yK0],
      ];
      for (const [a, b] of [[0, 1], [1, 2], [2, 3]]) wall(col, K[a], K[b], x0, x1);
      cap(col, K, x0, -1);
      cap(col, K, x1, 1);

      const px0 = sx * BR_X - PL_W / 2, px1 = sx * BR_X + PL_W / 2;
      const Q = [[ZW, 0], [ZW + PL_T, 0], [ZW + PL_T, PL_H], [ZW, PL_H]];
      for (let k = 0; k < 4; k++) wall(col, Q[k], Q[(k + 1) % 4], px0, px1);
      cap(col, Q, px0, -1);
      cap(col, Q, px1, 1);
    }
  }

  const merged = mergeGeometries(
    Object.entries(buf).filter(([, p]) => p.length)
      .map(([hex, p]) => prep(posGeo(p), Number(hex)))
  );
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'awning-body';

  const g = new THREE.Group();
  g.name = 'fabric-awning';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;
