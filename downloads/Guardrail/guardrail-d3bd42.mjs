/*
 * Guardrail
 * https://polyfork.dev/asset/guardrail-d3bd42
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './guardrail-d3bd42.mjs';
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
 *   colorway    choice  'galvanized'   'galvanized' | 'painted-white'
 *   rail        color   '#c2c7cd'      any hex or THREE.Color
 *   reflectors  toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/guardrail-d3bd42-params.json
 *
 * SPECS  146 triangles, 1 material, 4 x 0.9 x 0.34 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'galvanized':    { rail: 0xc2c7cd, steel: 0xafb5bb },
  'painted-white': { rail: 0xf0f1ec, steel: 0xafb5bb },
};
const BASE = {
  rail:      0xc2c7cd,
  steel:     0xafb5bb,
  bolt:      0x4c4f57,
  reflector: 0xf1f2ef,
  rust:      0x875e43,
};

export const presets = COLORWAYS;
export const params = {
  colorway: { type: 'choice', default: 'galvanized', label: 'Colorway',
              options: ['galvanized', 'painted-white'],
              describe: 'curated steel finish: bare weathered galvanize or white-painted rail' },
  rail:     { type: 'color', default: '#c2c7cd', label: 'Rail',
              describe: 'albedo of the corrugated W-beam rail' },
  reflectors: { type: 'toggle', default: true, label: 'Reflectors', icon: '🔆',
              affects: 'geometry',
              describe: 'white mid-span reflector plate and delineator tabs above the posts' },
};

const parts = [];
const add = (g, c) => parts.push({ g, c });

function box(w, h, d, x, y, z) { return new THREE.BoxGeometry(w, h, d).translate(x, y, z); }

function tubeBox(w, h, z0, z1, x, y) {
  const hw = w / 2, hh = h / 2, pos = [];
  quad(pos, [x-hw, y+hh, z1], [x+hw, y+hh, z1], [x+hw, y+hh, z0], [x-hw, y+hh, z0]);
  quad(pos, [x-hw, y-hh, z0], [x+hw, y-hh, z0], [x+hw, y-hh, z1], [x-hw, y-hh, z1]);
  quad(pos, [x+hw, y-hh, z1], [x+hw, y-hh, z0], [x+hw, y+hh, z0], [x+hw, y+hh, z1]);
  quad(pos, [x-hw, y-hh, z0], [x-hw, y-hh, z1], [x-hw, y+hh, z1], [x-hw, y+hh, z0]);
  return posGeo(pos);
}

function decal(w, h, x, y, z) {
  const hw = w / 2, hh = h / 2, pos = [];
  quad(pos, [x-hw, y-hh, z], [x+hw, y-hh, z], [x+hw, y+hh, z], [x-hw, y+hh, z]);
  return posGeo(pos);
}

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function rivet(cx, cy, cz, nx, ny, nz, r = 0.013, h = 0.008) {
  const n = new THREE.Vector3(nx, ny, nz).normalize();
  const up = Math.abs(n.y) > 0.9 ? new THREE.Vector3(1,0,0) : new THREE.Vector3(0,1,0);
  const t = new THREE.Vector3().crossVectors(up, n).normalize();
  const b = new THREE.Vector3().crossVectors(n, t).normalize();
  const apex = [cx + n.x*h, cy + n.y*h, cz + n.z*h];
  const ring = [];
  for (let i = 0; i < 6; i++) {
    const a = (i/6) * Math.PI * 2, cs = Math.cos(a)*r, sn = Math.sin(a)*r;
    ring.push([cx + t.x*cs + b.x*sn, cy + t.y*cs + b.y*sn, cz + t.z*cs + b.z*sn]);
  }
  const pos = [];
  for (let i = 0; i < 6; i++) tri(pos, apex, ring[i], ring[(i+1)%6]);
  return posGeo(pos);
}

const RAIL_BACK = 0.20;
const SHEET = 0.012;

const PROFILE_FRONT = [
  [0.010, 0.44],
  [0.078, 0.50],
  [0.020, 0.565],
  [0.020, 0.655],
  [0.078, 0.72],
  [0.010, 0.80],
];
const VALLEY_Z = 0.20 + 0.020;
function railGeometry() {
  const shape = new THREE.Shape();
  shape.moveTo(PROFILE_FRONT[0][0], PROFILE_FRONT[0][1]);
  for (let i = 1; i < PROFILE_FRONT.length; i++) shape.lineTo(PROFILE_FRONT[i][0], PROFILE_FRONT[i][1]);
  for (let i = PROFILE_FRONT.length - 1; i >= 0; i--) {
    shape.lineTo(PROFILE_FRONT[i][0] - SHEET, PROFILE_FRONT[i][1]);
  }
  shape.closePath();
  const g = new THREE.ExtrudeGeometry(shape, { depth: 4.0, bevelEnabled: false });

  g.rotateY(-Math.PI / 2);
  g.translate(2.0, 0, RAIL_BACK);
  return g;
}

export function createAsset(opts = {}) {

  const cw = COLORWAYS[opts.colorway] || COLORWAYS[params.colorway.default];
  const C = { ...BASE, ...cw };
  if (opts.rail) C.rail = new THREE.Color(opts.rail).getHex();
  const showReflectors = opts.reflectors !== undefined ? !!opts.reflectors : params.reflectors.default;

  parts.length = 0;

  add(railGeometry(), C.rail);

  const POST_X = 1.38;
  for (const s of [-1, 1]) {
    const px = s * POST_X;

    add(box(0.16, 0.74, 0.13, px, 0.37, 0), C.steel);

    add(tubeBox(0.16, 0.14, 0.055, 0.215, px, 0.62), C.steel);

    add(rivet(px, 0.62, VALLEY_Z + 0.004, 0, 0, 1), C.bolt);

    add(decal(0.022, 0.035, px, 0.585, VALLEY_Z + 0.005), C.rust);

    add(rivet(s * 1.86, 0.62, VALLEY_Z + 0.004, 0, 0, 1), C.bolt);
  }

  add(decal(0.42, 0.016, -0.9, 0.585, VALLEY_Z + 0.005), C.rust);
  add(decal(0.10, 0.018, 0.95, 0.60, VALLEY_Z + 0.005), C.rust);

  if (showReflectors) {

    add(decal(0.12, 0.06, 0, 0.61, VALLEY_Z + 0.005), C.reflector);

    for (const s of [-1, 1]) {
      const px = s * POST_X;
      add(box(0.08, 0.11, 0.024, px, 0.845, 0.208), C.steel);
      add(decal(0.07, 0.09, px, 0.845, 0.220 + 0.005), C.reflector);
    }
  }

  const ZC = -0.11;
  const geos = parts.map(({ g, c }) => {
    if (ZC) g.translate(0, 0, ZC);
    g = g.toNonIndexed();
    g.deleteAttribute('uv');
    g.deleteAttribute('normal');
    const col = new THREE.Color(c);
    const n = g.attributes.position.count;
    const arr = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) { arr[i*3] = col.r; arr[i*3+1] = col.g; arr[i*3+2] = col.b; }
    g.setAttribute('color', new THREE.BufferAttribute(arr, 3));
    return g;
  });
  const merged = mergeGeometries(geos);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'guardrail-mesh';

  const g = new THREE.Group();
  g.name = 'guardrail-section';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
export default createAsset;
