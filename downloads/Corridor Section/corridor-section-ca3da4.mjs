/*
 * Corridor Section
 * https://polyfork.dev/asset/corridor-section-ca3da4
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './corridor-section-ca3da4.mjs';
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
 *   colorway     choice  'nasa-white'   'nasa-white' | 'gunmetal' | 'regolith' | 'deep-navy'
 *   hull         color   '#b4b7bc'      any hex or THREE.Color
 *   shoulder     color   '#989ea7'      any hex or THREE.Color
 *   collar       color   '#b2684b'      any hex or THREE.Color
 *   bore         color   '#5f6570'      any hex or THREE.Color
 *   rail         color   '#3d3f47'      any hex or THREE.Color
 *   glow         color   '#7fe9e0'      any hex or THREE.Color
 *   plates       range   3              2 to 5
 *   girth        range   2.66           2.32 to 2.78
 *   boreWidth    range   2.1            1.8 to 2.4
 *   lightRail    toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/corridor-section-ca3da4-params.json
 *
 * SPECS  424 triangles, 2 materials, 3 x 3 x 4 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'nasa-white': { hull: 0xb4b7bc, shoulder: 0x989ea7, collar: 0xb2684b, bore: 0x5f6570, rail: 0x3d3f47, glow: 0x7fe9e0 },
  'gunmetal':   { hull: 0x878c94, shoulder: 0x737785, collar: 0x975b44, bore: 0x5f6570, rail: 0x1d1e26, glow: 0x7fe9e0 },
  'regolith':   { hull: 0xc1a078, shoulder: 0x856f5d, collar: 0xb2684b, bore: 0x5f6570, rail: 0x3e2f2b, glow: 0x7fe9e0 },
  'deep-navy':  { hull: 0x434e67, shoulder: 0x5f6570, collar: 0xb2684b, bore: 0x3d3f47, rail: 0x1d1e26, glow: 0x7fe9e0 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: { type: 'choice', default: 'nasa-white', label: 'Colorway',
              options: ['nasa-white', 'gunmetal', 'regolith', 'deep-navy'],
              describe: 'curated kit-palette scheme; sets all six zone albedos at once. nasa-white is the shipped off-white hull with astro-orange collars; gunmetal is a darker grey service module; regolith is a dust-tan hull weathered by the rust terrain, orange collars kept; deep-navy is a blue-grey hull with orange collars. The cyan glow bar stays cyan in every preset' },
  hull:     { type: 'color', default: '#b4b7bc', label: 'Hull',
              describe: 'albedo of the off-white pressurized plates between the two end collars — the dominant mass, about half the faces' },
  shoulder: { type: 'color', default: '#989ea7', label: 'Shoulder flange',
              describe: 'albedo of the grey flange ring just inboard of each collar; keep it one value step darker than the hull or the end step stops reading' },
  collar:   { type: 'color', default: '#b2684b', label: 'Collar ring',
              describe: 'albedo of the astro-orange mating band at both ends and of the flat octagonal end faces; the accent colour of the piece' },
  bore:     { type: 'color', default: '#5f6570', label: 'Bore lining',
              describe: 'albedo of the interior wall seen through the open passage; mid gunmetal so the mouth reads as a hole, never black' },
  rail:     { type: 'color', default: '#3d3f47', label: 'Light rail',
              describe: 'albedo of the dark housing the glow bar sits in, on both side facets' },
  glow:     { type: 'color', default: '#7fe9e0', label: 'Glow strip',
              describe: 'colour of the two emissive light bars (self-lit material, also the night colour source); the only hue off the kit menu' },
  plates:   { type: 'range', default: 3, min: 2, max: 5, label: 'Plate count', affects: 'geometry',
              describe: 'how many bolted plate segments the hull is divided into between the shoulders (integer 2-5). Each extra plate adds a real stepped seam groove cut into the hull at a constant pitch, so 2 reads as two long panels with one seam and 5 as a short-pitch banded pipe. Triangle count rises with the count; plate length is 3.36 m / plates' },
  girth:    { type: 'range', default: 2.66, min: 2.32, max: 2.78, label: 'Hull girth', affects: 'geometry',
              describe: 'across-flats width of the hull plates in metres. The collar stays at the kit standard 3.00 m whatever this is, so the knob sets how far the end boss stands proud: 2.32 = slim tube with a 0.34 m chunky telescoping flange per side, 2.66 = the shipped 0.17 m step, 2.78 = fat barrel with thin end rims. The shoulder flange tracks it, staying just over half way between hull and collar. Overall size never changes' },
  boreWidth:{ type: 'range', default: 2.10, min: 1.80, max: 2.40, label: 'Bore', affects: 'geometry',
              describe: 'across-flats width of the open passage in metres, measured at the mouth lip. 1.80 = thick-walled bulkhead with a wide orange end face and a small hole, 2.10 = the shipped 2.1 m passage (ample for a 1.8 m astronaut), 2.40 = thin-walled tunnel that is nearly all opening. Clamped so the hull keeps a 0.12 m wall, so a wide bore on a slim girth stops short of the maximum' },
  lightRail:{ type: 'toggle', default: true, label: 'Light rail', affects: 'geometry',
              describe: 'the two side light rails (dark housing plus the emissive cyan bar). Off = bare hull plates on both side facets, for a dark or unpowered corridor; the hull is closed underneath, nothing is left behind. Off also drops the second (emissive) material and the night glow zone' },
};

export const rig = {};
export const detach = [];

export const night = {
  glow: { color: '#b6fff6', intensity: 1,
          describe: 'the cyan side light bars burning at full after dark' },
  bore: { color: '#5d8189', intensity: 0.45,
          describe: 'soft spill from the lit interior through the open passage' },
};

const ZONE_KEYS = ['hull', 'shoulder', 'collar', 'bore', 'rail', 'glow'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['nasa-white'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.hull) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

const r4 = (x) => Math.round(x * 1e4) / 1e4;

const HALF_L = 2.00;
const AXIS_Y = 1.50;
const H_COLLAR = 1.50;
const END_CH = 0.05;

const parts = [];
const add = (g, c) => parts.push({ g, c });

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const OCT_K = Math.cos(Math.PI / 8);
function oct(h) {
  const r = h / OCT_K, pts = [];
  for (let i = 0; i < 8; i++) {
    const a = Math.PI / 8 + i * Math.PI / 4;
    pts.push([Math.cos(a) * r, Math.sin(a) * r + AXIS_Y]);
  }
  return pts;
}

function skin(profile, outward = true) {
  const pos = [];
  for (let s = 0; s < profile.length - 1; s++) {
    const [z0, h0] = profile[s], [z1, h1] = profile[s + 1];
    const a = oct(h0), b = oct(h1);
    for (let k = 0; k < 8; k++) {
      const j = (k + 1) % 8;
      const p0 = [a[k][0], a[k][1], z0], p1 = [a[j][0], a[j][1], z0];
      const p2 = [b[j][0], b[j][1], z1], p3 = [b[k][0], b[k][1], z1];
      if (outward) quad(pos, p0, p1, p2, p3); else quad(pos, p3, p2, p1, p0);
    }
  }
  return posGeo(pos);
}

function annulus(z, hi, ho, plusZ) {
  const A = oct(hi), B = oct(ho), pos = [];
  for (let k = 0; k < 8; k++) {
    const j = (k + 1) % 8;
    const i0 = [A[k][0], A[k][1], z], i1 = [A[j][0], A[j][1], z];
    const o0 = [B[k][0], B[k][1], z], o1 = [B[j][0], B[j][1], z];
    if (plusZ) quad(pos, i0, o0, o1, i1); else quad(pos, i0, i1, o1, o0);
  }
  return posGeo(pos);
}

function box(w, h, d, x, y, z, dropPlusX) {
  const g = new THREE.BoxGeometry(w, h, d);
  const idx = [...g.getIndex().array];
  g.setIndex(dropPlusX ? idx.slice(6) : [...idx.slice(0, 6), ...idx.slice(12)]);
  return g.translate(x, y, z);
}

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

const DEFAULTS = { colorway: 'nasa-white', plates: 3, girth: 2.66, boreWidth: 2.10, lightRail: true };

export function createAsset(opts = {}) {
  parts.length = 0;
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);

  const H_PLATE = r4(clamp(num(o.girth, 2.66), 2.32, 2.78) / 2);
  const H_SHOULDER = r4(H_PLATE + (H_COLLAR - H_PLATE) * 0.5294);
  const H_MID = r4(H_PLATE - 0.06);
  const H_BORE = r4(Math.min(clamp(num(o.boreWidth, 2.10), 1.80, 2.40) / 2, H_MID - 0.12));
  const H_LIP = r4(H_BORE + 0.05);
  const nP = Math.round(clamp(num(o.plates, 3), 2, 5));
  const railOn = !(o.lightRail === false || o.lightRail === 'false' || o.lightRail === 0);

  const g = new THREE.Group();
  g.name = 'corridor-section';

  const H_END = r4(H_COLLAR - END_CH);
  add(skin([[-HALF_L, H_END], [r4(-HALF_L + END_CH), H_COLLAR], [-1.87, H_COLLAR]]), C.collar);
  add(skin([[ 1.87, H_COLLAR], [r4(HALF_L - END_CH), H_COLLAR], [ HALF_L, H_END]]), C.collar);

  add(skin([[-1.87, H_COLLAR], [-1.845, H_SHOULDER], [-1.71, H_SHOULDER]]), C.shoulder);
  add(skin([[ 1.71, H_SHOULDER], [ 1.845, H_SHOULDER], [ 1.87, H_COLLAR]]), C.shoulder);

  const HULL_END = 1.67, GW = 0.08;
  const PITCH = r4(3.36 / nP);
  const prof = [[-1.71, H_SHOULDER], [-HULL_END, H_PLATE]];
  for (let i = 1; i < nP; i++) {
    const c = r4((i - nP / 2) * PITCH);
    prof.push([r4(c - GW), H_PLATE], [r4(c - GW + 0.04), H_MID],
              [r4(c + GW - 0.04), H_MID], [r4(c + GW), H_PLATE]);
  }
  prof.push([HULL_END, H_PLATE], [1.71, H_SHOULDER]);
  add(skin(prof), C.hull);

  add(skin([[-HALF_L, H_LIP], [-1.94, H_BORE], [1.94, H_BORE], [HALF_L, H_LIP]], false), C.bore);

  add(annulus(-HALF_L, H_LIP, H_END, false), C.collar);
  add(annulus( HALF_L, H_LIP, H_END, true), C.collar);

  const RAIL_Y = 1.55;
  const glowGeos = [];
  if (railOn) {
    for (const sx of [1, -1]) {
      add(box(0.115, 0.20, 3.32, r4(sx * (H_PLATE - 0.0525)), RAIL_Y, 0, sx < 0), C.rail);
      glowGeos.push(box(0.053, 0.13, 3.24, r4(sx * (H_PLATE - 0.0135)), RAIL_Y, 0, sx < 0));
    }
  }

  const hull = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  hull.computeVertexNormals();
  const hullMesh = new THREE.Mesh(hull, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  hullMesh.name = 'hull';
  g.add(hullMesh);

  if (glowGeos.length) {
    const glow = mergeGeometries(glowGeos.map(x => { const q = x.toNonIndexed(); q.deleteAttribute('uv'); q.deleteAttribute('normal'); return q; }));
    glow.computeVertexNormals();
    const glowMesh = new THREE.Mesh(glow, new THREE.MeshStandardMaterial({
      color: C.glow, emissive: new THREE.Color(C.glow), emissiveIntensity: 1.0,
      roughness: 0.4, metalness: 0, flatShading: true,
    }));
    glowMesh.name = 'light-strip';
    g.add(glowMesh);
  }

  return g;
}

export default createAsset;
