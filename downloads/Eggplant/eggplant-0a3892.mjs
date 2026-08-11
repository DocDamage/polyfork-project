/*
 * Eggplant
 * https://polyfork.dev/asset/eggplant-0a3892
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './eggplant-0a3892.mjs';
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
 * SPECS  114 triangles, 1 material, 0.16 x 0.28 x 0.12 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SKIN  = 0x5c2a78;
const CALYX = 0x7cb03a;
const STEM  = 0x4d7a24;

const parts = [];
const add = (g, c) => parts.push({ g, c });

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const H = 0.215;
const TOP_Y = 0.205;
const PROFILE = [
  [0.000, 0.000],
  [0.050, 0.022],
  [0.063, 0.070],
  [0.058, 0.120],
  [0.043, 0.170],
  [0.020, TOP_Y],

];

const LEAN = 0.042;
const bendX = (y) => LEAN * (y / H) ** 2;
const bendSlope = (y) => 2 * LEAN * y / (H * H);

const body = new THREE.LatheGeometry(
  PROFILE.map(([r, y]) => new THREE.Vector2(r, y)), 7
);
{
  const p = body.attributes.position;
  for (let i = 0; i < p.count; i++) p.setX(i, p.getX(i) + bendX(p.getY(i)));
}
add(body, SKIN);

const calyxPos = [];
{
  const apexTop = [0, 0.034, 0];
  const apexBot = [0, 0.000, 0];
  const ring = [];
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * Math.PI * 2;
    const tip = i % 2 === 0;

    const r = tip ? 0.062 : 0.038;
    const y = tip ? -0.040 : -0.004;
    ring.push([Math.cos(a) * r, y, Math.sin(a) * r]);
  }
  for (let i = 0; i < 12; i++) {
    tri(calyxPos, apexTop, ring[(i + 1) % 12], ring[i]);
    tri(calyxPos, apexBot, ring[i], ring[(i + 1) % 12]);
  }
}
const calyx = posGeo(calyxPos);

const stem = new THREE.CylinderGeometry(0.013, 0.020, 0.062, 5)
  .translate(0, 0.041, 0);

for (const g of [calyx, stem]) {
  g.translate(bendX(TOP_Y), TOP_Y + 0.003, 0);
}
add(calyx, CALYX);
add(stem, STEM);

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

export function createAsset() {
  const merged = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.55, metalness: 0,
  }));
  mesh.name = 'eggplant';
  const group = new THREE.Group();
  group.name = 'eggplant';
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};

export default createAsset;
