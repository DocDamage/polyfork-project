/*
 * Path Stone B
 * https://polyfork.dev/asset/path-stone-b-6ed75c
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './path-stone-b-6ed75c.mjs';
 *   scene.add(createAsset());
 *
 * OPTIONS  createAsset({ ... }) — no arguments rebuilds this exact stone.
 *
 *   colorway     choice  'warm-sand'   warm-sand, pale-limestone, slate, mossy
 *   stone        color   '#c9baa4'     the one stone albedo (a rock is one zone)
 *   sides        range   10            6 chunky angular flag .. 12 river-worn slab
 *   width        range   0.3           0.2 narrow stepping stone .. 0.44 m broad flag
 *   thickness    range   0.055         0.028 thin flag .. 0.06 m full slab
 *   chamfer      range   1             0.3 crisp cut flagstone .. 1.8 rounded boulder
 *   crown        range   0.28          0 flat paver .. 0.4 lumpy cobble
 *
 *   scene.add(createAsset({ colorway: 'slate', sides: 7, width: 0.22 }));
 *
 * `presets` holds the colorway swatches and `night` the after-dark map (empty:
 * a stone emits nothing). Full machine-readable schema, with a `describe` per
 * knob: https://polyfork.dev/cdn/path-stone-b-6ed75c-params.json
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
 * SPECS  66 triangles, 1 material, 0.62 x 0.055 x 0.3 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

export const COLORWAYS = {
  'warm-sand':      { stone: 0xC9BAA4 },
  'pale-limestone': { stone: 0xE8DCC0 },
  'slate':          { stone: 0x3C4550 },
  'mossy':          { stone: 0x7D8A5A },
};
export const presets = COLORWAYS;

const LEN = 0.62;
const DEF_WID = 0.30;
const DEF_HGT = 0.055;
const DEF_N = 10;
const DEF_CROWN = 0.28;

export const params = {
  colorway:  { type: 'choice', default: 'warm-sand', label: 'Colorway',
               options: ['warm-sand', 'pale-limestone', 'slate', 'mossy'],
               describe: 'curated stone type; sets the single stone albedo (warm-sand = the approved warm sandy limestone, pale-limestone = the kit\'s bright light stone, slate = dark blue-grey, mossy = lichened green-grey for shaded runs). A rock is one material, so this is the only colour zone there is' },
  stone:     { type: 'color', default: '#c9baa4', label: 'Stone',
               describe: 'albedo of the whole slab — crown, chamfer band, ground rim and underside alike. This asset has a single colour zone by design (craft rule 7b): every facet-to-facet tone difference in a render is scene light on flat-shaded normals, never paint' },
  sides:     { type: 'range', default: DEF_N, min: 6, max: 12, label: 'Sides', affects: 'geometry',
               describe: 'number of straight sides in the plan outline (whole numbers 6-12). 6 = a chunky angular flag with long flanks and a coarsely faceted rim, 10 = the approved worn stone, 12 = a smoother river-worn slab. Drives the triangle count directly (~6-7 tris per side, 38 triangles at the low end and 78 at the high end, against the 80 a path stone is allowed) and regenerates the whole angle/radius/crown table set, so each value is its own stone rather than the same outline subdivided. The long ends stay STRADDLED by a pair of corners at every count — a corner sitting on the major axis spikes the tip into a knife edge' },
  width:     { type: 'range', default: DEF_WID, min: 0.20, max: 0.44, label: 'Width', affects: 'geometry',
               describe: 'front-to-back size of the plan outline in metres; the 0.62 m long axis is fixed by the kit scatter contract, so this is the plan ASPECT knob. 0.20 = a narrow 3.1:1 stepping stone for a single-file trail, 0.30 = the approved 2.1:1 lozenge, 0.44 = a broad 1.4:1 flag two people can pass on. It is a rebuild, not a stretch: the chamfer inset is a constant 30 mm in METRES, so a narrow stone spends far more of its width on the bevel and its crown is a slim ridge, while a broad one keeps a wide flat tread' },
  thickness: { type: 'range', default: DEF_HGT, min: 0.028, max: 0.06, label: 'Thickness', affects: 'geometry',
               describe: 'total height in metres from the ground plane to the highest point of the crown. 0.028 = a thin worn flag sunk almost flush with the trail, 0.055 = the approved slab, 0.06 = the chunkiest a path stone may be (the BUILD 8bc ceiling, which the top of this range sits exactly on so a scattered run always stays walkable). The three section bands — ground rim, widest line, chamfer — and the crown relief all rebuild at the new height in the same ratios. A rock has nothing repeating in its section to multiply, so this knob rebuilds proportions rather than a structure; the honest size knob with a triangle count behind it is `sides`' },
  chamfer:   { type: 'range', default: 1, min: 0.3, max: 1.8, label: 'Chamfer breadth', affects: 'geometry',
               describe: 'how worn the edge is: the plan width of the hero top bevel, as a multiple of the approved constant 30 mm inset, with the vertical ground rim moving the OPPOSITE way. 0.3 = a crisp cut flagstone, nearly all tall vertical face under a hairline lip; 1 = the approved worn bevel over a short rim; 1.8 = a rounded-off boulder whose whole side is one wide skirt and whose tread is a small faceted island. The inset stays a constant distance in METRES all the way round at every value — a proportional inset would ramp the ends twice as far as the sides and taper the silhouette to a point — and is floored so no corner band can collapse the tread (measured: the chamfer band never drops below 11% of the slab height at any knob combination)' },
  crown:     { type: 'range', default: DEF_CROWN, min: 0, max: 0.4, label: 'Crown relief', affects: 'geometry',
               describe: 'depth of the hewn unevenness across the top, as a share of total thickness. 0 = a dead-flat paver walked smooth, every top facet in one plane and the tread reading as one tone; 0.28 = the default hewn stone (14 mm of relief on a 55 mm slab, which is what breaks the top into a dozen facets at visibly different tones); 0.4 = a lumpy cobble that visibly rocks. Total height is held at the thickness knob at every value, so the relief eats DOWN into the slab and can never breach the 0.06 m path-stone ceiling; the walkable top stays within the top quarter of the slab throughout' },
};

export const rig = {};
export const detach = [];
export const night = {};

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
function warmed(seed) { const r = prng(seed); for (let i = 0; i < 12; i++) r(); return r; }
function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['warm-sand'];
  return { stone: (hexOf(o.stone) ?? cw.stone) & 0xFFFFFF };
}

const ANGLES_10 = [0.40, 1.02, 1.60, 2.18, 2.74, 3.54, 4.16, 4.74, 5.32, 5.88];

const CROWN_F_10 = [0.70, 0.15, 0.52, 0.00, 0.82, 0.25, 0.10, 0.62, 0.18, 0.45];

const P_EXP = 2.6;

function tablesFor(n) {
  if (n === DEF_N) return { ang: ANGLES_10, crownF: CROWN_F_10 };
  const rnd = warmed(4391 + n * 7919);
  const ang = [], crownF = [];
  for (let i = 0; i < n; i++) {
    ang.push((i + 0.5) * 2 * Math.PI / n + (rnd() - 0.5) * (Math.PI / n) * 0.45);
    crownF.push((0.13 + i * 0.6180339887498949) % 1);
  }
  const nearTip = (a) => Math.min(Math.abs(((a % Math.PI) + Math.PI) % Math.PI),
                                  Math.PI - Math.abs(((a % Math.PI) + Math.PI) % Math.PI));
  for (let pass = 0; pass < 12; pass++) {
    if (ang.every((a) => nearTip(a) > 0.14)) break;
    for (let i = 0; i < n; i++) ang[i] += 0.05;
  }
  return { ang, crownF };
}

const DEFAULTS = {
  colorway: 'warm-sand', sides: DEF_N, width: DEF_WID,
  thickness: DEF_HGT, chamfer: 1, crown: DEF_CROWN,
};

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const g = new THREE.Group();
  g.name = 'path-stone-b';

  const N = Math.round(clamp(num(o.sides, DEF_N), 6, 12));
  const WID = clamp(num(o.width, DEF_WID), 0.20, 0.44);
  const HGT = clamp(num(o.thickness, DEF_HGT), 0.028, 0.06);
  const CH = clamp(num(o.chamfer, 1), 0.3, 1.8);
  const CROWN = clamp(num(o.crown, DEF_CROWN), 0, 0.4);
  const { ang: ANGLES, crownF: CROWN_F } = tablesFor(N);

  const rand = prng(31771);

  const rim = [];
  const topY = [];
  for (let i = 0; i < N; i++) {
    const a = ANGLES[i] + (rand() - 0.5) * 0.18;
    const ca = Math.cos(a), sa = -Math.sin(a);
    const t = 0.5 / Math.pow(Math.pow(Math.abs(ca), P_EXP) + Math.pow(Math.abs(sa), P_EXP), 1 / P_EXP);
    const j = 0.90 + rand() * 0.20;
    rim.push([ca * t * j, sa * t * j]);
    rand();
    topY.push(HGT * (1 - CROWN * (1 - CROWN_F[i])));
  }

  const Y_RIM = HGT * (0.40 + (1 - CH) * 0.13);
  const BASE_IN = 0.006 * (HGT / DEF_HGT);
  const TOP_IN = 0.030 * CH;
  let x0 = Infinity, x1 = -Infinity, z0 = Infinity, z1 = -Infinity;
  for (const [x, z] of rim) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); z0 = Math.min(z0, z); z1 = Math.max(z1, z); }
  const rimM = rim.map(([x, z]) => [
    (x - (x0 + x1) / 2) * LEN / (x1 - x0),
    (z - (z0 + z1) / 2) * WID / (z1 - z0),
  ]);
  const inset = (i, d) => {
    const [x, z] = rimM[i], len = Math.hypot(x, z);
    const k = Math.max(0.35, (len - d) / len);
    return [x * k, z * k];
  };
  const RING = [rimM.map((_, i) => inset(i, BASE_IN)), rimM, rimM.map((_, i) => inset(i, TOP_IN))];
  const P = (i, ring, y) => [RING[ring][i][0], y, RING[ring][i][1]];
  const BASE = 0, WIDE = 1, TOP = 2;

  const pos = [];

  for (let i = 1; i < N - 1; i++) {
    tri(pos, P(0, BASE, 0), P(i + 1, BASE, 0), P(i, BASE, 0));
  }

  for (let i = 0; i < N; i++) {
    const n = (i + 1) % N;
    quad(pos, P(i, BASE, 0), P(n, BASE, 0), P(n, WIDE, Y_RIM), P(i, WIDE, Y_RIM));
  }

  for (let i = 0; i < N; i++) {
    const n = (i + 1) % N;
    quad(pos, P(i, WIDE, Y_RIM), P(n, WIDE, Y_RIM), P(n, TOP, topY[n]), P(i, TOP, topY[i]));
  }

  const crown = RING[TOP].map((_, i) => P(i, TOP, topY[i]));
  const cx = crown.reduce((s, p) => s + p[0], 0) / N;
  const cz = crown.reduce((s, p) => s + p[2], 0) / N;
  const hx = (Math.max(...crown.map(p => p[0])) - Math.min(...crown.map(p => p[0]))) / 2;
  const hz = (Math.max(...crown.map(p => p[2])) - Math.min(...crown.map(p => p[2]))) / 2;
  const M = clamp(Math.round(N / 2), 3, 5);
  const irnd = warmed(2287 + N * 131);
  const inner = [];
  for (let k = 0; k < M; k++) {
    const phi = (k + 0.5) * 2 * Math.PI / M + (irnd() - 0.5) * (Math.PI / M) * 0.7;
    const f = 0.38 + irnd() * 0.22;
    const g = k === 0 ? 1 : 0.15 + irnd() * 0.7;
    inner.push([cx + f * hx * Math.cos(phi), HGT * (1 - CROWN * (1 - g)), cz - f * hz * Math.sin(phi)]);
  }
  const bearing = (p) => Math.atan2(-(p[2] - cz), p[0] - cx);
  const apart = (a, b) => Math.abs(((a - b + Math.PI) % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI) - Math.PI);
  let i = 0, k = 0, uo = 0, ui = 0;
  for (let t = 1; t < M; t++) {
    if (apart(bearing(inner[t]), bearing(crown[0])) < apart(bearing(inner[k]), bearing(crown[0]))) k = t;
  }
  while (uo < N || ui < M) {
    if (ui >= M || (uo < N && (uo + 1) / N <= (ui + 1) / M)) {
      const n = (i + 1) % N;
      tri(pos, inner[k], crown[i], crown[n]); i = n; uo++;
    } else {
      const n = (k + 1) % M;
      tri(pos, crown[i], inner[n], inner[k]); k = n; ui++;
    }
  }
  for (let t = 1; t < M - 1; t++) tri(pos, inner[0], inner[t], inner[t + 1]);

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));

  geo.computeBoundingBox();
  const bb = geo.boundingBox;
  geo.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  const p = geo.attributes.position;
  const col = new Float32Array(p.count * 3);
  const c = new THREE.Color(zonesFor(String(o.colorway), o).stone);
  for (let i = 0; i < p.count; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));

  geo.computeVertexNormals();

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'stone-slab';
  g.add(mesh);
  return g;
}

export default createAsset;
