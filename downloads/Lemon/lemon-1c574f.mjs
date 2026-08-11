/*
 * Lemon
 * https://polyfork.dev/asset/lemon-1c574f
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './lemon-1c574f.mjs';
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
 * SPECS  124 triangles, 1 material, 0.12 x 0.06 x 0.08 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const YELLOW = 0xffc61a;
const LEAF   = 0x57a83a;
const STEM   = 0x3a6f28;

const L = 0.115;
const R = 0.032;

const PROFILE = [[0, 0], [0.11, 0.36], [0.30, 0.82], [0.50, 1.0], [0.70, 0.82], [0.89, 0.36], [1, 0]];
function radiusAt(t) {
  t = Math.min(1, Math.max(0, t));
  for (let i = 1; i < PROFILE.length; i++) {
    const [t0, k0] = PROFILE[i - 1], [t1, k1] = PROFILE[i];
    if (t <= t1) return R * (k0 + (k1 - k0) * (t - t0) / (t1 - t0));
  }
  return 0;
}

const parts = [];
const add = (g, c) => parts.push({ g, c });

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
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

function leafGeo(len, wid, th) {
  const A = [0, 0, 0], B = [len, 0, 0];
  const C = [len * 0.4, 0, wid / 2], D = [len * 0.4, 0, -wid / 2];
  const T = [len * 0.4, th, 0], U = [len * 0.4, -th * 0.5, 0];
  const p = [];
  tri(p, A, C, T); tri(p, C, B, T); tri(p, B, D, T); tri(p, D, A, T);
  tri(p, A, U, C); tri(p, C, U, B); tri(p, B, U, D); tri(p, D, U, A);
  return posGeo(p);
}

export function createAsset() {

  const pts = PROFILE.map(([t]) => new THREE.Vector2(radiusAt(t), t * L - L / 2));
  const body = new THREE.LatheGeometry(pts, 8);
  body.rotateZ(-Math.PI / 2);
  body.rotateX(Math.PI / 8);
  add(body, YELLOW);

  const dir = new THREE.Vector3(1, 0, 0);
  const sLen = 0.016;
  const stem = new THREE.CylinderGeometry(0.005, 0.006, sLen, 5, 1);
  stem.translate(0, sLen / 2 - 0.005, 0);
  stem.applyQuaternion(new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), dir));

  const seat = new THREE.Vector3(L / 2 - 0.002, 0, 0);
  stem.translate(seat.x, seat.y, seat.z);
  add(stem, STEM);

  const leaf = leafGeo(0.062, 0.044, 0.006);
  leaf.rotateX(0.25);
  leaf.rotateZ(0.22);
  leaf.rotateY(Math.PI - 1.05);

  const top = seat.clone().addScaledVector(dir, sLen - 0.010);
  leaf.translate(top.x, top.y, top.z);
  add(leaf, LEAF);

  const mesh = finish(parts);
  parts.length = 0;

  mesh.geometry.computeBoundingBox();
  const b = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2);

  const g = new THREE.Group();
  g.name = 'lemon';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
