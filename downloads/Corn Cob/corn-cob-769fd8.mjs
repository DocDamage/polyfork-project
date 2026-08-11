/*
 * Corn Cob
 * https://polyfork.dev/asset/corn-cob-769fd8
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './corn-cob-769fd8.mjs';
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
 * SPECS  112 triangles, 1 material, 0.12 x 0.21 x 0.12 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const KERNEL_A = '#fbd050';
const KERNEL_B = '#d9971a';
const HUSK_A   = '#5da53c';
const HUSK_B   = '#3a7327';

const SIDES = 6;

const RINGS = [
  [0.000, 0.032],
  [0.021, 0.046],
  [0.052, 0.050],
  [0.083, 0.051],
  [0.114, 0.051],
  [0.145, 0.048],
  [0.171, 0.043],
  [0.193, 0.032],
];
const TIP_Y = 0.210;

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const parts = [];
const add = (g, c) => parts.push({ g, c });

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

function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function solid(pts, faces) {
  const cx = pts.reduce((s,p)=>s+p[0],0)/pts.length;
  const cy = pts.reduce((s,p)=>s+p[1],0)/pts.length;
  const cz = pts.reduce((s,p)=>s+p[2],0)/pts.length;
  const pos = [];
  for (const [i,j,k] of faces) {
    const a = pts[i], b = pts[j], c = pts[k];
    const e1 = [b[0]-a[0], b[1]-a[1], b[2]-a[2]];
    const e2 = [c[0]-a[0], c[1]-a[1], c[2]-a[2]];
    const n = [e1[1]*e2[2]-e1[2]*e2[1], e1[2]*e2[0]-e1[0]*e2[2], e1[0]*e2[1]-e1[1]*e2[0]];
    const out = [a[0]-cx, a[1]-cy, a[2]-cz];
    if (n[0]*out[0] + n[1]*out[1] + n[2]*out[2] < 0) tri(pos, a, c, b);
    else tri(pos, a, b, c);
  }
  return posGeo(pos);
}

function cobR(y) {
  if (y <= RINGS[0][0]) return RINGS[0][1];
  for (let b = 0; b < RINGS.length - 1; b++) {
    const [ly, lr] = RINGS[b], [uy, ur] = RINGS[b + 1];
    if (y <= uy) return lr + (ur - lr) * ((y - ly) / (uy - ly));
  }
  const [ty, tr] = RINGS[RINGS.length - 1];
  return tr * Math.max(0, 1 - (y - ty) / (TIP_Y - ty));
}

function cob() {
  const ang = (i) => (i / SIDES) * Math.PI * 2;
  const pt = (i, y, r) => [Math.cos(ang(i)) * r, y, Math.sin(ang(i)) * r];
  const tipPt = [0, TIP_Y, 0];
  const basePt = [0, 0, 0];

  for (let i = 0; i < SIDES; i++) {
    const j = (i + 1) % SIDES;
    const capPos = [], tipPos = [];

    tri(capPos, basePt, pt(i, RINGS[0][0], RINGS[0][1]), pt(j, RINGS[0][0], RINGS[0][1]));
    add(posGeo(capPos), KERNEL_B);

    for (let b = 0; b < RINGS.length - 1; b++) {
      const [ly, lr] = RINGS[b], [uy, ur] = RINGS[b + 1];
      const pos = [];
      quad(pos, pt(i, ly, lr), pt(i, uy, ur), pt(j, uy, ur), pt(j, ly, lr));
      add(posGeo(pos), b < 2 ? (i % 2 === 0 ? HUSK_A : HUSK_B)
                             : ((i + b) % 2 === 0 ? KERNEL_A : KERNEL_B));
    }

    const [ty, tr] = RINGS[RINGS.length - 1];
    tri(tipPos, pt(i, ty, tr), tipPt, pt(j, ty, tr));
    add(posGeo(tipPos), i % 2 === 0 ? KERNEL_A : KERNEL_B);
  }
}

function husk() {

  const LEAVES = [
    [  20, 0.115, HUSK_A],
    [ 110, 0.088, HUSK_B],
    [ 200, 0.104, HUSK_B],
    [ 292, 0.079, HUSK_A],
  ];
  for (const [deg, tipY, color] of LEAVES) {
    const a = (deg * Math.PI) / 180;
    const d = [Math.cos(a), 0, Math.sin(a)];
    const t = [-Math.sin(a), 0, Math.cos(a)];
    const P = (rad, tan, y) => [d[0]*rad + t[0]*tan, y, d[2]*rad + t[2]*tan];

    const BELLY_Y = 0.034;

    const A = P(0.010, +0.024, 0.000);
    const B = P(0.010, -0.024, 0.000);

    const M = P(cobR(BELLY_Y) + 0.014, 0.000, BELLY_Y);
    const T = P(cobR(tipY)    + 0.007, 0.000, tipY);

    add(solid([A, B, T, M], [[0,1,2],[0,1,3],[0,2,3],[1,2,3]]), color);
  }
}

export function createAsset() {
  parts.length = 0;
  const g = new THREE.Group();
  g.name = 'corn-cob';

  cob();
  husk();

  const mesh = finish(parts);
  mesh.name = 'corn';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};

export default createAsset;
