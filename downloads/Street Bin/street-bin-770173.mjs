/*
 * Street Bin
 * https://polyfork.dev/asset/street-bin-770173
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './street-bin-770173.mjs';
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
 *   colorway  choice  'pavement-steel' 'pavement-steel' | 'municipal-green' | 'sakura-cream' | 'vermilion-shrine'
 *   shell     color   '#A9AFB4'      any hex or THREE.Color
 *   base      color   '#2E3134'      any hex or THREE.Color
 *   liner     color   '#3C4145'      any hex or THREE.Color
 *   tallness  range   0.9            0.68 to 1.16
 *   facets    range   14             8 to 18
 *   mouth     range   0.126          0.085 to 0.168
 *
 * Every option is described in full at https://polyfork.dev/cdn/street-bin-770173-params.json
 *
 * SPECS  420 triangles, 1 material, 0.59 x 0.9 x 0.58 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'pavement-steel':   { shell: '#A9AFB4', base: '#2E3134', liner: '#3C4145' },
  'municipal-green':  { shell: '#2F6B4F', base: '#1B1D20', liner: '#2E3134' },
  'sakura-cream':     { shell: '#E4E2DC', base: '#4E5459', liner: '#6B7278' },
  'vermilion-shrine': { shell: '#B5462F', base: '#2E3134', liner: '#42352A' },
};

const H0       = 0.900;
const R_BODY   = 0.262;
const R_HOOD   = 0.288;

const R_BASE   = 0.296;
const R_PAN    = 0.240;

const BASE_H   = 0.130;
const HOOD_H   = 0.150;

const PAN_Y    = 0.022;

const BASE_CHAM = 0.016;
const BASE_WALL = 0.100;

const SHOULDER  = 0.046;
const HOOD_WALL = 0.066;
const HOOD_CHAM = 0.040;
const R_HOOD_TOP = 0.252;
const COLLAR_PROUD = 0.044;
const COLLAR_CHAM  = 0.014;
const COLLAR_RING  = 0.057;
const MOUTH_CHAM   = 0.014;

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
function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function revolve(pts, colors, seg) {
  const ring = (r, y) => {
    const out = [];
    for (let i = 0; i < seg; i++) {
      const a = ((i + 0.5) / seg) * Math.PI * 2;
      out.push([Math.sin(a) * r, y, Math.cos(a) * r]);
    }
    return out;
  };
  const buckets = new Map();
  for (let s = 0; s < pts.length - 1; s++) {
    const [r0, y0] = pts[s], [r1, y1] = pts[s + 1];

    if (Math.abs(r1 - r0) < 1e-6 && Math.abs(y1 - y0) < 1e-6) continue;
    if (!buckets.has(colors[s])) buckets.set(colors[s], []);
    const out = buckets.get(colors[s]);
    const A = ring(r0, y0), B = ring(r1, y1);
    const capA = [0, y0, 0], capB = [0, y1, 0];
    for (let i = 0; i < seg; i++) {
      const j = (i + 1) % seg;
      if (r0 < 1e-6) tri(out, capA, B[j], B[i]);
      else if (r1 < 1e-6) tri(out, A[i], A[j], capB);
      else quad(out, A[i], A[j], B[j], B[i]);
    }
  }
  return [...buckets].map(([c, pos]) => ({ g: posGeo(pos), c }));
}

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'pavement-steel', label: 'Colorway',
    options: ['pavement-steel', 'municipal-green', 'sakura-cream', 'vermilion-shrine'],
    describe: 'Curated kit-coherent scheme; sets shell, base ring and throat liner ' +
              'together. pavement-steel is the approved grey street bin with a ' +
              'near-black plinth; municipal-green is a darker park bin; sakura-cream a ' +
              'pale shopfront bin with a slate plinth; vermilion-shrine a red bin for ' +
              'the shrine precinct. Every scheme keeps the liner darker than the shell ' +
              'so the mouth still reads as a hole.',
  },
  shell: {
    type: 'color', default: COLORWAYS['pavement-steel'].shell, label: 'Shell',
    describe: 'Albedo of the whole powder-coated steel moulding — the barrel wall, the ' +
              'overhanging hood with its chamfer, and the raised collar around the ' +
              'mouth. This is the bin\'s dominant colour and covers roughly two thirds ' +
              'of its surface. Overrides the colorway.',
  },
  base: {
    type: 'color', default: COLORWAYS['pavement-steel'].base, label: 'Base ring',
    describe: 'Albedo of the flared plinth at the foot, including both its chamfers and ' +
              'the recessed floor pan inside it. Keep it well DARKER than Shell — it is ' +
              'the asset\'s only strong value break and what grounds it on pavement. ' +
              'Overrides the colorway.',
  },
  liner: {
    type: 'color', default: COLORWAYS['pavement-steel'].liner, label: 'Throat liner',
    describe: 'Albedo of the inner sleeve and floor seen down the posting aperture. ' +
              'Keep it clearly darker than Shell or the mouth stops reading as an ' +
              'opening and starts reading as a painted disc. Overrides the colorway.',
  },
  tallness: {
    type: 'range', default: 0.90, min: 0.68, max: 1.16, label: 'Tallness',
    affects: 'geometry',
    describe: 'Overall height in metres from the pavement to the collar crown; the ' +
              '0.592 m widest diameter never changes. REBUILT, not stretched: the base ' +
              'ring keeps its exact 0.130 m section and the hood its exact 0.150 m ' +
              'section at every value, chamfer widths are untouched, and only the plain ' +
              'barrel wall between them lengthens (0.27 m at 0.68, 0.62 m at 0.90, ' +
              '0.75 m at 1.16). A drawn-steel wall has NOTHING that repeats along its ' +
              'height — no ribs, no courses, no bays — so the triangle count is ' +
              'deliberately constant here; the Facets knob is the one that rebuilds ' +
              'with a changing count. 0.68 is a squat alley bin, 1.16 a tall station ' +
              'bin the same width.',
  },
  facets: {
    type: 'range', default: 14, min: 8, max: 18, step: 1, label: 'Facets',
    affects: 'geometry',
    describe: 'Number of flat vertical panels around the bin — the roundness of the ' +
              'turned form, and the one knob that changes the triangle count. 14 is the ' +
              'approved look, matching the refs: round enough to read as rolled steel at ' +
              'street scale while every panel still catches its own tone. 8 is a hard ' +
              'octagonal bin whose corners read from any angle; 18 is nearly smooth. ' +
              'Body, hood, collar, mouth and base ring all share the one facet grid at ' +
              'every value, so no fitting can drift off the wall.',
  },
  mouth: {
    type: 'range', default: 0.126, min: 0.085, max: 0.168, label: 'Mouth radius',
    affects: 'geometry',
    describe: 'Radius in metres of the posting aperture in the hood — 0.126 is the ' +
              'approved Ø 0.252 opening. The raised collar, the hood\'s flat top ' +
              'annulus and the inner throat sleeve are all re-derived from it, so the ' +
              'collar stays a constant 0.057 m wide ring hugging the hole at every ' +
              'value. 0.085 is a narrow cigarette-bin slot ringed by a broad hood; ' +
              '0.168 is a wide open litter mouth that leaves only a thin hood brim. ' +
              'Reads directly in the hero three-quarter, which looks down onto the hood.',
  },
};

function clamp(v, lo, hi) { return Math.min(Math.max(v, lo), hi); }

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  return {
    shell: p.shell !== undefined ? p.shell : cw.shell,
    base:  p.base  !== undefined ? p.base  : cw.base,
    liner: p.liner !== undefined ? p.liner : cw.liner,
  };
}

export function createAsset(p = {}) {
  const C   = resolve(p);
  const H   = clamp(p.tallness ?? params.tallness.default, params.tallness.min, params.tallness.max);
  const SEG = Math.round(clamp(p.facets ?? params.facets.default, params.facets.min, params.facets.max));
  const M   = clamp(p.mouth ?? params.mouth.default, params.mouth.min, params.mouth.max);

  const BT = H - HOOD_H;
  const CO = M + COLLAR_RING;
  const ANNULUS = H - COLLAR_PROUD;

  const FLOOR = BT - 0.24 * H;

  const P = [
    [0,          PAN_Y],
    [R_PAN,      PAN_Y,               C.base],
    [R_BASE,     0,                   C.base],
    [R_BASE,     BASE_CHAM,           C.base],
    [R_BASE,     BASE_WALL,           C.base],
    [R_BODY,     BASE_H,              C.base],
    [R_BODY,     BT - SHOULDER,       C.shell],
    [R_HOOD,     BT,                  C.shell],
    [R_HOOD,     BT + HOOD_WALL,      C.shell],
    [R_HOOD_TOP, BT + HOOD_WALL + HOOD_CHAM, C.shell],
    [CO,         ANNULUS,             C.shell],
    [CO,         H - COLLAR_CHAM,     C.shell],
    [CO - COLLAR_CHAM, H,             C.shell],
    [M + MOUTH_CHAM,   H,             C.shell],
    [M,          H - MOUTH_CHAM,      C.liner],
    [M,          FLOOR,               C.liner],
    [0,          FLOOR,               C.liner],
  ];

  P[2][0] = R_BASE - BASE_CHAM;

  const parts = revolve(P.map(([r, y]) => [r, y]), P.slice(1).map(s => s[2]), SEG);

  const g = new THREE.Group();
  g.name = 'street-bin';
  const mesh = finish(parts);
  mesh.name = 'bin';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;
