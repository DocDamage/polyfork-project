/*
 * Young Pine
 * https://polyfork.dev/asset/young-pine-0d7695
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './young-pine-0d7695.mjs';
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
 *   colorway   choice  'fresh-green'  'fresh-green' | 'deep-forest' | 'spring-flush' | 'golden-larch'
 *   needles    color   '#5f9a4b'      any hex or THREE.Color
 *   bark       color   '#5d4430'      any hex or THREE.Color
 *   snow       color   '#f4ece0'      any hex or THREE.Color
 *   season     choice  'summer'       'summer' | 'snow'
 *   tallness   range   3              2 to 3.15
 *   facets     range   12             9 to 13
 *   lumpiness  range   0.4            0 to 1
 *
 * Every option is described in full at https://polyfork.dev/cdn/young-pine-0d7695-params.json
 *
 * SPECS  414 triangles, 1 material, 1.86 x 3 x 1.89 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'fresh-green': {
    needles: '#5f9a4b', bark: '#5d4430', snow: '#f4ece0',
  },
  'deep-forest': {
    needles: '#3d6b34', bark: '#4a3527', snow: '#e0d2b4',
  },
  'spring-flush': {
    needles: '#77b258', bark: '#75563b', snow: '#f4ece0',
  },
  'golden-larch': {
    needles: '#8fa84a', bark: '#8c6a47', snow: '#f4ece0',
  },
};
export const presets = COLORWAYS;

const ZONES = ['needles', 'bark', 'snow'];

export const params = {
  colorway: {
    type: 'choice', default: 'fresh-green', label: 'Colorway',
    options: ['fresh-green', 'deep-forest', 'spring-flush', 'golden-larch'],
    describe: 'Curated kit-palette scheme; sets every zone colour at once. ' +
      'fresh-green is the shipped build — one bright mid green over the whole canopy on ' +
      'mid brown bark. deep-forest ' +
      'drops the whole ramp one rung for planting inside a closed wood, where a bright ' +
      'sapling reads as a hole in the shade. spring-flush lifts it two rungs to pale ' +
      'new growth. golden-larch takes the canopy to olive-gold on warm bark, so the ' +
      'same tree reads as a turning larch. Every scheme keeps the canopy a single ' +
      'committed green: the value range across the foliage comes from the flat-shaded ' +
      'facets and the lumpiness knob, never from a second painted tone.',
  },
  needles: {
    type: 'color', default: '#5f9a4b', label: 'Needles',
    describe: 'The canopy green, and the ONLY colour on the foliage — every tier, every ' +
      'facet column, cap to underside, one uniform tone. This is the colour the tree is ' +
      'recognised by at kit distance, so keep it a committed leaf green; the light and ' +
      'the facets do the shading, so nothing here should be pre-darkened.',
  },
  bark: {
    type: 'color', default: '#5d4430', label: 'Bark',
    describe: 'Albedo of the whole trunk, ONE uniform tone on every facet — the taper ' +
      'and the ground flare are real geometry, so the scene lights shade them. Keep it ' +
      'clearly darker than the needles or the short trunk stops reading against the ' +
      'foliage underside hanging over it.',
  },
  snow: {
    type: 'color', default: '#f4ece0', label: 'Snow',
    describe: 'Albedo of the snow caps. Only exists when `season` is "snow"; ignored ' +
      'in summer. Never pure white — a broken off-white sits in the kit.',
  },
  season: {
    type: 'choice', default: 'summer', label: 'Season', affects: 'geometry',
    options: ['summer', 'snow'],
    describe: 'State knob. "summer" is bare green foliage, the shipped build. "snow" ' +
      'builds a real snow shell over the crown cap and along the upper shoulder of ' +
      'every tier — added geometry standing 35-50 mm proud of the needles with its own ' +
      'downturned lip, not a repaint, so it shades itself and casts. Adds triangles.',
  },
  tallness: {
    type: 'range', default: 3.0, min: 2.0, max: 3.15, label: 'Tallness (m)',
    affects: 'geometry',
    describe: 'Total height in metres, and it REBUILDS rather than scaling: whole ' +
      'foliage TIERS are added as the tree grows, at a 0.75-0.94 m pitch, so 2.0 m is ' +
      'a single-tier seedling that is just a fat rounded cone on a stub trunk, 3.0 m ' +
      'is the shipped two-tier reference tree, and 3.15 m is a three-tier one already ' +
      'turning into a small conifer, its leader taking a smaller share of the tree the ' +
      'way a real one does. The triangle count moves with the tier count (270 / 438 / ' +
      '558 at the default facet count). Spread follows height but not proportionally — ' +
      'the tree narrows from 0.66 wide per unit tall at 2.0 m to 0.62 at 3.15 m, ' +
      'because a young conifer loses bushiness as it climbs. The range is skewed hard ' +
      'DOWNWARD on purpose: the variant proof frames the default bbox, so any real ' +
      'growth at the top end crops its own crown out of the shot.',
  },
  facets: {
    type: 'range', default: 12, min: 9, max: 13, label: 'Facets', affects: 'geometry',
    describe: 'Number of flat planes around the canopy. 9 is a coarse angular crystal ' +
      'sapling with obvious corners on every rim; 13 is a smoother, rounder bush of a ' +
      'tree. The trunk stays a chunky 6-sided prism at every value. Changes the ' +
      'triangle count, and also how many columns the deep-green clumps can own.',
  },
  lumpiness: {
    type: 'range', default: 0.40, min: 0.0, max: 1.0, label: 'Lumpiness',
    affects: 'geometry',
    describe: 'How irregular the foliage columns are, on unchanged overall dimensions. ' +
      'At 0.00 both tiers are perfectly turned solids of revolution and the tree reads ' +
      'as a clipped topiary — clean, graphic, good for a stylised orchard row. At 0.40 ' +
      '(shipped default) the columns wander about 7% in radius and 35 mm in height, ' +
      'which is the gently uneven mass the reference shows. At 1.00 the columns swing ' +
      '17% and the outline is properly scalloped, a shaggy wild sapling. Mirror-folded, ' +
      'so the tree stays bilaterally symmetric at every value.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

function prng(seed = 1) {
  let s = seed % 2147483647;
  if (s <= 0) s += 2147483646;
  const f = () => (s = (s * 16807) % 2147483647) / 2147483647;
  for (let i = 0; i < 8; i++) f();
  return f;
}

const clamp = (v, a, b) => Math.min(b, Math.max(a, v));

const STEP_K = 0.85;
function jitterTable(S, m, seed, amp) {
  const rnd = prng(seed);
  const cache = new Map();
  const out = [];
  for (let i = 0; i < S; i++) {
    const j = ((m - i) % S + S) % S;
    const key = Math.min(i, j);
    if (!cache.has(key)) cache.set(key, (rnd() * 2 - 1) * amp);
    out.push(cache.get(key));
  }
  const lim = STEP_K * Math.abs(amp);
  for (let pass = 0; pass < 4; pass++) {
    const next = out.map((v, i) => {
      const a = out[(i - 1 + S) % S], b = out[(i + 1) % S];
      const lo = Math.max(a, b) - lim, hi = Math.min(a, b) + lim;
      return lo > hi ? (a + b) / 2 : clamp(v, lo, hi);
    });
    for (let i = 0; i < S; i++) out[i] = next[i];
  }
  return out;
}

const WAIST_K = 0.70;

const WAIST_W = 0.28;

const WAIST_T = WAIST_K * 0.86;

const NECK_S = 0.95;

const CROWN = [
  [0.0000, 0.125, 0.15],
  [0.1750, 0.660, 0.60],
  [0.3500, 0.773, 0.85],
  [0.5250, 0.887, 1.00],
  [0.7000, 1.000, 1.00],
  [0.8600, 0.900, 0.90],
  [0.9500, WAIST_K, WAIST_W],
  [1.0000, WAIST_K, WAIST_W],
];

const TIER_MID = [
  [0.0550, WAIST_T, WAIST_W],
  [0.2100, 0.870, 0.55],
  [0.3600, 1.000, 1.00],
  [0.6300, 1.012, 1.00],
  [0.8600, 0.995, 0.95],
  [0.9500, WAIST_K, WAIST_W],
  [1.0000, WAIST_K, WAIST_W],
];

const TIER_BOT = [
  [0.0550, WAIST_T, WAIST_W],
  [0.2100, 0.870, 0.55],
  [0.3600, 1.000, 1.00],
  [0.6600, 1.012, 1.00],
  [0.8600, 0.995, 0.95],
  [1.0000, 0.956, 0.90],
];

const UNDER = [
  [0.6300, 0.510, 0.60],
  [1.0000, 0.138, 0.00],
];

const TRUNK = [
  [0.000, 0.205],
  [0.235, 0.172],
  [0.590, 0.150],
  [1.000, 0.138],
];
const TRUNK_SIDES = 6;

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const col = { ...cw };

  for (const k of ZONES) if (p[k] !== undefined) col[k] = p[k];
  const num = (k) => {
    const s = params[k], v = p[k];
    if (v === undefined || v === null || Number.isNaN(Number(v))) return s.default;
    return clamp(Number(v), s.min, s.max);
  };
  return {
    col,
    H: num('tallness'),
    S: Math.round(num('facets')),
    lump: num('lumpiness'),
    snowy: (params.season.options.includes(p.season) ? p.season : params.season.default) === 'snow',
  };
}

function sample(table, r0, w0, s) {
  let p0 = [0, r0, w0];
  for (const e of table) {
    if (e[0] >= s) {
      const t = (s - p0[0]) / Math.max(1e-6, e[0] - p0[0]);
      return { k: p0[1] + (e[1] - p0[1]) * t, w: p0[2] + (e[2] - p0[2]) * t };
    }
    p0 = e;
  }
  return { k: p0[1], w: p0[2] };
}

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const C = P.col;
  const H = P.H, S = P.S;

  const nTiers = clamp(Math.round((H - 0.88) / 0.90), 1, 3);
  const nSkirt = nTiers - 1;

  const crownShare = nSkirt >= 2 ? 1.15 : 1.47;
  const yBase = 0.185 * H;
  const u = (H - yBase) / (0.26 + crownShare + nSkirt);
  const underSpan = 0.26 * u;
  const yFlank0 = yBase + underSpan;

  const R = H * (0.360 - 0.0155 * H);
  const lvlR = (L) => R * Math.pow(0.86, L);
  const waistY = (t) => yFlank0 + (t + 1) * u;
  const crownBottom = nSkirt > 0 ? waistY(nSkirt - 1) : yFlank0;
  const crownH = H - crownBottom;
  const rC = lvlR(nSkirt);

  const step = (Math.PI * 2) / S;
  const phase = (Math.PI % step) / 2;
  const mFold = Math.floor(Math.PI / step);

  const jr = [], jy = [];
  for (let L = 0; L <= nSkirt; L++) {
    jr.push(jitterTable(S, mFold, 211 + L * 41, 0.17 * P.lump));
    jy.push(jitterTable(S, mFold, 733 + L * 59, 0.10 * u * P.lump));
  }

  const pos = [], col = [];
  const tmp = new THREE.Color();
  const push3 = (a, b, c, hex) => {
    pos.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
    tmp.set(hex);
    for (let i = 0; i < 3; i++) col.push(tmp.r, tmp.g, tmp.b);
  };

  const band = (A, B, colOf) => {
    for (let i = 0; i < A.length; i++) {
      const k = (i + 1) % A.length;
      const hex = colOf(i);
      push3(A[i], B[k], B[i], hex);
      push3(A[i], A[k], B[k], hex);
    }
  };
  const fanFrom = (p, B, colOf) => {
    for (let i = 0; i < B.length; i++) push3(p, B[(i + 1) % B.length], B[i], colOf(i));
  };
  const fanTo = (A, p, colOf) => {
    for (let i = 0; i < A.length; i++) push3(A[i], A[(i + 1) % A.length], p, colOf(i));
  };
  const flat = (hex) => () => hex;

  function ring(r, y, L, w, dr = 0, dy = 0) {
    const v = [];
    const tr = jr[L], ty = jy[L];
    for (let i = 0; i < S; i++) {
      const a = phase + i * step;
      const rr = r * (1 + tr[i] * w) + dr;
      v.push([Math.cos(a) * rr, y + ty[i] * w + dy, Math.sin(a) * rr]);
    }
    return v;
  }

  const st = [];

  const crownTbl = nSkirt === 0 ? [...CROWN.slice(0, -2), [1.0000, 0.860, 0.85]]
    : nSkirt >= 2 ? CROWN.filter((_, i) => i !== 2 && i !== 3)
      : CROWN;
  for (const [s, k, w] of crownTbl) {
    st.push({ r: k * rC, y: H - s * crownH, L: s >= NECK_S ? Math.max(0, nSkirt - 1) : nSkirt, w });
  }
  for (let t = nSkirt - 1; t >= 0; t--) {
    const top = waistY(t), rT = lvlR(t);
    for (const [s, k, w] of (t > 0 ? TIER_MID : TIER_BOT)) {
      st.push({ r: k * rT, y: top - s * u, L: s >= NECK_S ? Math.max(0, t - 1) : t, w });
    }
  }
  for (const [s, k, w] of UNDER) {
    st.push({ r: k * lvlR(0), y: yFlank0 - s * underSpan, L: 0, w });
  }

  const rings = st.map(s => ring(s.r, s.y, s.L, s.w));

  const foliage = flat(C.needles);

  fanFrom([0, H, 0], rings[0], foliage);
  for (let i = 0; i < rings.length - 1; i++) band(rings[i], rings[i + 1], foliage);

  if (P.snowy) {
    const off = 0.035 * (H / 3), lip = 0.006 * (H / 3), up = 0.050 * (H / 3);

    const capA = ring(CROWN[0][1] * rC, H, nSkirt, CROWN[0][2], off * 0.3, up);
    const c1 = sample(CROWN, CROWN[0][1], CROWN[0][2], 0.30);
    const c2 = sample(CROWN, CROWN[0][1], CROWN[0][2], 0.35);
    const cA = ring(c1.k * rC, H - 0.30 * crownH, nSkirt, c1.w, off, up);
    const cB = ring(c2.k * rC, H - 0.35 * crownH, nSkirt, c2.w, lip, lip);
    fanFrom([0, H + up, 0], capA, flat(C.snow));
    band(capA, cA, flat(C.snow));
    band(cA, cB, flat(C.snow));
    for (let t = nSkirt - 1; t >= 0; t--) {
      const top = waistY(t), rT = lvlR(t), tbl = t > 0 ? TIER_MID : TIER_BOT;
      const r0 = WAIST_K * lvlR(t + 1) / rT;

      const A = ring(r0 * rT, top - tbl[0][0] * u, t, WAIST_W);
      const s1 = sample(tbl, r0, WAIST_W, 0.26), s2 = sample(tbl, r0, WAIST_W, 0.31);
      const B = ring(s1.k * rT, top - 0.26 * u, t, s1.w, off, up);
      band(A, B, flat(C.snow));
      band(B, ring(s2.k * rT, top - 0.31 * u, t, s2.w, lip, lip), flat(C.snow));
    }
  }

  const tTop = yBase + 0.14 * u;
  const tk = Math.pow(H / 3, 0.75);
  const tj = jitterTable(TRUNK_SIDES, TRUNK_SIDES / 2, 907, 0.045);
  const tRings = TRUNK.map(([s, r]) => {
    const v = [];
    for (let i = 0; i < TRUNK_SIDES; i++) {
      const a = i * ((Math.PI * 2) / TRUNK_SIDES);
      const rr = r * tk * (1 + tj[i]);
      v.push([Math.cos(a) * rr, s * tTop, Math.sin(a) * rr]);
    }
    return v;
  }).reverse();
  for (let i = 0; i < tRings.length - 1; i++) band(tRings[i], tRings[i + 1], flat(C.bark));
  fanTo(tRings[tRings.length - 1], [0, 0, 0], flat(C.bark));

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.computeVertexNormals();

  const mesh = new THREE.Mesh(geo, treeMaterial());
  mesh.name = 'young-pine-mesh';

  geo.computeBoundingBox();
  const bb = geo.boundingBox;
  geo.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  const g = new THREE.Group();
  g.name = 'young-pine';
  g.add(mesh);

  const uT = mesh.material.userData.uTime;
  g.userData.tick = (seconds) => { uT.value = seconds; };
  return g;
}

const SWAY_Y0 = 0.55, SWAY_K = 0.0090;
function treeMaterial() {
  const mat = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });
  mat.userData.uTime = { value: 0 };
  mat.onBeforeCompile = (sh) => {
    sh.uniforms.uTime = mat.userData.uTime;
    sh.vertexShader = 'uniform float uTime;\n' + sh.vertexShader.replace(
      '#include <begin_vertex>',
      `#include <begin_vertex>
      float swayH = max(0.0, transformed.y - ${SWAY_Y0.toFixed(3)});
      float swayK = swayH * swayH * ${SWAY_K.toFixed(5)};
      transformed.x += swayK * sin(uTime * 1.15) * (0.78 + 0.22 * sin(transformed.z * 1.7));
      transformed.z += swayK * sin(uTime * 0.83 + 1.3) * 0.7;`,
    );
  };
  mat.customProgramCacheKey = () => 'young-pine-sway';
  return mat;
}

export default createAsset;
