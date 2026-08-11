/*
 * Bagel
 * https://polyfork.dev/asset/bagel-d8a6bb
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './bagel-d8a6bb.mjs';
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
 * SPECS  138 triangles, 1 material, 0.11 x 0.03 x 0.11 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const R = 0.036;
const RH = 0.021;
const RV = 0.021;

const CRUST = 0xbb7530;
const TOP   = 0xe3a95c;
const HOLE  = 0x744016;
const SEED  = 0xf7e7c2;

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

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function triOut(out, a, b, c, ref) {
  const ux = b[0]-a[0], uy = b[1]-a[1], uz = b[2]-a[2];
  const vx = c[0]-a[0], vy = c[1]-a[1], vz = c[2]-a[2];
  const nx = uy*vz - uz*vy, ny = uz*vx - ux*vz, nz = ux*vy - uy*vx;
  const cx = (a[0]+b[0]+c[0])/3 - ref[0];
  const cy = (a[1]+b[1]+c[1])/3 - ref[1];
  const cz = (a[2]+b[2]+c[2])/3 - ref[2];
  if (nx*cx + ny*cy + nz*cz < 0) { const t = b; b = c; c = t; }
  out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]);
}
function quadOut(out, a, b, c, d, ref) { triOut(out, a, b, c, ref); triOut(out, a, c, d, ref); }

const SECTION = [0, 50, 130, 230, 310];

const BAND_COLOR = [CRUST, TOP, HOLE, CRUST, CRUST];

const N = 11;
const CY = Math.sin(SECTION[1] * Math.PI / 180) * RV;
const TOP_Y = 2 * CY;
const rand = prng(9);
const jit = [];
for (let i = 0; i < N; i++) jit.push(0.955 + rand() * 0.09);

function ringPoint(i, thetaDeg) {
  const phi = (i % N) / N * Math.PI * 2;
  const t = thetaDeg * Math.PI / 180;
  const s = jit[i % N];
  const rad = (R + RH * Math.cos(t)) * s;
  return [Math.cos(phi) * rad, CY + RV * Math.sin(t), Math.sin(phi) * rad];
}
function tubeCentre(i) {
  const phi = (i % N) / N * Math.PI * 2;
  const rad = R * jit[i % N];
  return [Math.cos(phi) * rad, CY, Math.sin(phi) * rad];
}

for (let b = 0; b < SECTION.length; b++) {
  const ta = SECTION[b], tb = SECTION[(b + 1) % SECTION.length];
  const pos = [];
  for (let i = 0; i < N; i++) {
    const ref = tubeCentre(i);
    quadOut(pos, ringPoint(i, ta), ringPoint(i + 1, ta), ringPoint(i + 1, tb), ringPoint(i, tb), ref);
  }
  add(posGeo(pos), BAND_COLOR[b]);
}

const UPRIGHT = new THREE.Quaternion().setFromUnitVectors(
  new THREE.Vector3(1, 1, 1).normalize(), new THREE.Vector3(0, 1, 0));
const SEEDS = [[0.35, 0.036], [1.15, 0.030], [1.9, 0.040], [2.75, 0.032],
               [3.6, 0.039], [4.4, 0.031], [5.4, 0.037]];
for (const [phi, rad] of SEEDS) {
  const g = new THREE.TetrahedronGeometry(0.0075, 0);
  g.applyQuaternion(UPRIGHT);
  g.scale(1, 0.55, 1);
  g.rotateY(phi * 1.7);
  g.translate(Math.cos(phi) * rad, TOP_Y - 0.0018, Math.sin(phi) * rad);
  add(g, SEED);
}

export function createAsset() {
  const group = new THREE.Group();
  group.name = 'bagel';
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
