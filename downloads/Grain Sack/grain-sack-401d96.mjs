/*
 * Grain Sack
 * https://polyfork.dev/asset/grain-sack-401d96
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './grain-sack-401d96.mjs';
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
 *   colorway     choice  'burlap-tan'   'burlap-tan' | 'flour-white' | 'dark-hessian' | 'seed-green'
 *   cloth        color   '#b89b72'      any hex or THREE.Color
 *   cord         color   '#6f4e37'      any hex or THREE.Color
 *   plumpness    range   1              0.78 to 1.32
 *   crownPoints  range   5              4 to 7
 *   slouch       range   0              0 to 1
 *
 * Every option is described in full at https://polyfork.dev/cdn/grain-sack-401d96-params.json
 *
 * SPECS  448 triangles, 1 material, 0.58 x 0.73 x 0.55 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'burlap-tan':   { cloth: 0xB89B72, cord: 0x6F4E37 },
  'flour-white':  { cloth: 0xE8DCC0, cord: 0x8C6A4A },
  'dark-hessian': { cloth: 0x8C6A4A, cord: 0x3C4550 },
  'seed-green':   { cloth: 0x7D8A5A, cord: 0x3C4550 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: { type: 'choice', default: 'burlap-tan', label: 'Colorway',
              options: ['burlap-tan', 'flour-white', 'dark-hessian', 'seed-green'],
              describe: 'curated cloth+cord scheme from the kit palette; burlap-tan is raw jute with a brown cord (the shipped look), flour-white a pale bleached mill sack, dark-hessian heavy brown sacking with a slate cord, seed-green a dyed green seed sack' },
  cloth:    { type: 'color', default: '#b89b72', label: 'Cloth',
              describe: 'albedo of the whole sack fabric — body, saggy base and gathered crown are one flat tone; all facet-to-facet variation you see is scene lighting, not paint' },
  cord:     { type: 'color', default: '#6f4e37', label: 'Cord',
              describe: 'albedo of the rope tie band, the knot lump and the two hanging tail-ends; keep it darker than the cloth or the tie stops reading as a separate part' },
  plumpness: { type: 'range', default: 1.0, min: 0.78, max: 1.32, label: 'Plumpness', icon: '🎈', affects: 'geometry',
              describe: 'how full the sack is: rebuilds every profile ring below the throat, so 0.78 is a slack half-empty sack ~0.44 m across the belly and 1.32 a stuffed one ~0.74 m across, with the saggy base lip and the drooping cord tails swinging out to match. Height, neck, tie and crown are untouched. Girth has no repeating structure in it, so this knob changes ring RADII, not triangle count — the count moves with crownPoints instead' },
  crownPoints: { type: 'range', default: 5, min: 4, max: 7, label: 'Crown points', icon: '✳️', affects: 'geometry',
              describe: 'integer number of points in the ruffled star of gathered fabric above the tie (4-7, default 5). It also sets the body facet resolution — the sack is built on two facets per point, so 4 is a chunky 8-sided sack with a broad four-pointed crown and 7 a rounder 14-sided one with a fine seven-pointed rosette' },
  slouch:   { type: 'range', default: 0, min: 0, max: 1, label: 'Slouch', icon: '🫠', affects: 'geometry',
              describe: 'how far the sack slumps out of plumb: 0 is the upright shipped sack, 1 pushes the belly ~0.09 m backward (-Z) and lets the neck and crown lean the same distance forward (+Z), an S-curve that breaks the turned-pot rotational symmetry. The base footprint never moves, so it still sits flat on y=0' },
};

export const rig = {};
export const detach = [];

export const night = {};

const ZONE_KEYS = ['cloth', 'cord'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['burlap-tan'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.cloth) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }

function prep(geo, hex) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i*3] = c.r; col[i*3+1] = c.g; col[i*3+2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

const DEFAULTS = { colorway: 'burlap-tan', plumpness: 1.0, crownPoints: 5, slouch: 0 };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const plump = clamp(num(o.plumpness, 1), 0.78, 1.32);
  const P = Math.round(clamp(num(o.crownPoints, 5), 4, 7));
  const S = clamp(num(o.slouch, 0), 0, 1);

  const g = new THREE.Group();
  g.name = 'grain-sack';

  const H = 0.70;
  const M = P * 2;

  const rand = prng(7);

  const PROFILE = [
    [0.00, 0.185],
    [0.05, 0.272],
    [0.16, 0.292],
    [0.32, 0.282],
    [0.48, 0.240],
    [0.60, 0.165],
    [0.70, 0.108],
    [0.74, 0.100],
    [0.82, 0.132],
    [0.91, 0.150],
    [1.00, 0.150],
  ];
  const rProfile = (t) => {
    for (let i = 0; i < PROFILE.length - 1; i++) {
      const [t0, r0] = PROFILE[i], [t1, r1] = PROFILE[i + 1];
      if (t <= t1) { const f = (t - t0) / (t1 - t0); return r0 + (r1 - r0) * f; }
    }
    return PROFILE[PROFILE.length - 1][1];
  };

  const bellyW = (t) => (t <= 0.48 ? 1 : Math.max(0, (0.70 - t) / 0.22));
  const rPlump = (t) => rProfile(t) * (1 + (plump - 1) * bellyW(t));

  const zLean = (t) => -S * 0.09 * Math.sin(1.5 * Math.PI * t);

  const starAmp = (t) => (t <= 0.74 ? 0 : ((t - 0.74) / 0.26) * 0.22);

  const rings = [];
  for (let i = 0; i < PROFILE.length; i++) {
    const t = PROFILE[i][0];
    const y = t * H;
    const rb = rPlump(t);
    const amp = starAmp(t);
    const zc = zLean(t);
    const ring = [];
    for (let j = 0; j < M; j++) {
      const a = (j / M) * Math.PI * 2;
      let r = rb;

      r *= 1 + amp * Math.cos(P * a);

      if (t < 0.18) r += Math.cos(4 * a) * -0.026 * (1 - t / 0.18);

      r *= 1 + (rand() - 0.5) * 0.06;
      let yj = y + (rand() - 0.5) * 0.012 * (t > 0.02 && t < 0.98 ? 1 : 0);

      if (amp > 0) yj += amp * 0.12 * Math.max(0, Math.cos(P * a));
      ring.push([Math.cos(a) * r, yj, Math.sin(a) * r + zc]);
    }
    rings.push(ring);
  }

  const pos = [];
  const col = [];
  const cCloth = new THREE.Color(C.cloth);
  const pushCol = (c) => { col.push(c.r, c.g, c.b); };

  const face = (a, b, c) => { tri(pos, a, b, c); pushCol(cCloth); pushCol(cCloth); pushCol(cCloth); };
  const faceQuad = (a, b, c, d) => { face(a, b, c); face(a, c, d); };

  for (let i = 0; i < rings.length - 1; i++) {
    for (let j = 0; j < M; j++) {
      const j1 = (j + 1) % M;
      const v00 = rings[i][j], v01 = rings[i][j1];
      const v10 = rings[i + 1][j], v11 = rings[i + 1][j1];
      faceQuad(v01, v00, v10, v11);
    }
  }

  const bc = [0, 0, 0];
  for (let j = 0; j < M; j++) {
    const j1 = (j + 1) % M;
    const b0 = rings[0][j].slice(); b0[1] = 0;
    const b1 = rings[0][j1].slice(); b1[1] = 0;
    face(bc, b0, b1);
  }

  const topRing = rings[rings.length - 1];
  const yRim = topRing[0][1];
  const zTop = zLean(1);
  const center = [0, yRim - 0.045, zTop];

  const inner = topRing.map((p) => {
    const a = Math.atan2(p[2] - zTop, p[0]);
    const r = 0.075;
    return [Math.cos(a) * r, yRim - 0.02, Math.sin(a) * r + zTop];
  });
  for (let j = 0; j < M; j++) {
    const j1 = (j + 1) % M;
    faceQuad(topRing[j1], topRing[j], inner[j], inner[j1]);
    face(inner[j1], inner[j], center);
  }

  const bodyGeo = new THREE.BufferGeometry();
  bodyGeo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  bodyGeo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));

  const geos = [bodyGeo];
  const yTie = 0.74 * H;
  const zTie = zLean(0.74);
  const tie = new THREE.TorusGeometry(0.100, 0.026, 6, M).rotateX(Math.PI / 2).translate(0, yTie, zTie);
  geos.push(prep(tie, C.cord));

  const knot = new THREE.OctahedronGeometry(0.045)
    .scale(1.0, 0.85, 0.8).translate(0, yTie, 0.105 + zTie);
  geos.push(prep(knot, C.cord));

  const cordSeg = (p0, p1, r0, r1) => {
    const dir = new THREE.Vector3().subVectors(p1, p0);
    const len = dir.length();
    const c = new THREE.CylinderGeometry(r1, r0, len, 5).translate(0, len / 2, 0);
    c.applyQuaternion(new THREE.Quaternion().setFromUnitVectors(
      new THREE.Vector3(0, 1, 0), dir.clone().normalize()));
    return c.translate(p0.x, p0.y, p0.z);
  };

  const V = (x, y, z) => new THREE.Vector3(x, y, z);
  const tail = (dx, spread) => {
    const a = V(dx, yTie - 0.015, 0.115 + zTie);
    const b = V((dx + spread * 0.035) * plump, yTie - 0.105, 0.155 * plump + zTie);
    const c = V((dx + spread * 0.085) * plump, yTie - 0.175, 0.205 * plump + zTie);
    geos.push(prep(cordSeg(a, b, 0.016, 0.012), C.cord));
    geos.push(prep(cordSeg(b, c, 0.012, 0.006), C.cord));
  };
  tail(-0.030, -1);
  tail(0.032, 1);

  const merged = mergeGeometries(geos);
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'grain-sack-mesh';
  g.add(mesh);

  return g;
}

export default createAsset;
