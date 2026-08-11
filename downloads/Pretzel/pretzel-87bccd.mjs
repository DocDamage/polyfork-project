/*
 * Pretzel
 * https://polyfork.dev/asset/pretzel-87bccd
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './pretzel-87bccd.mjs';
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
 * SPECS  136 triangles, 1 material, 0.14 x 0.13 x 0.04 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const CRUST = 0x7e4114;
const SALT = 0xf7f2e6;

const SX = 0.0570;
const SY = 0.0495;
const R = 0.0112;
const LIFT = 1.7 * R;

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

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const CP = [
  [ 0.74,  0.20, 0.1],
  [ 0.70,  0.22, 1.7],
  [ 1.06,  0.44, 1.7],
  [ 1.06,  0.88, 1.7],
  [ 0.58,  1.02, 1.7],
  [ 0.22,  0.80, 1.7],
  [ 0.00,  0.52, 1.7],
  [-0.72,  0.20, 0.0],
  [-0.86, -0.28, 0.0],
  [-0.58, -0.88, 0.0],
  [ 0.00, -1.08, 0.0],
  [ 0.58, -0.88, 0.0],
  [ 0.86, -0.28, 0.0],
  [ 0.72,  0.20, 0.0],
  [ 0.00,  0.52, 0.0],
  [-0.22,  0.80, 1.0],
  [-0.58,  1.02, 1.7],
  [-1.06,  0.88, 1.7],
  [-1.06,  0.44, 1.7],
  [-0.70,  0.22, 1.7],
  [-0.74,  0.20, 0.1],
];

const N = CP.length - 1;
const pts = CP.map(([x, y, z]) => new THREE.Vector3(x * SX, y * SY, z * R));
const tans = pts.map((_, i) => new THREE.Vector3()
  .subVectors(pts[Math.min(N, i + 1)], pts[Math.max(0, i - 1)]).normalize());

const radiusAt = (t) => R * (0.80 + 0.20 * Math.sin(Math.PI * t));

const Z = new THREE.Vector3(0, 0, 1);
const rings = [];
let u = new THREE.Vector3().crossVectors(Z, tans[0]);
if (u.lengthSq() < 1e-8) u.set(1, 0, 0);
for (let i = 0; i <= N; i++) {
  u.sub(tans[i].clone().multiplyScalar(u.dot(tans[i]))).normalize();
  const v = new THREE.Vector3().crossVectors(tans[i], u);
  const r = radiusAt(i / N), ring = [];
  for (let j = 0; j < 3; j++) {
    const a = Math.PI / 2 + (j / 3) * Math.PI * 2;
    const cs = Math.cos(a) * r, sn = Math.sin(a) * r;
    ring.push([
      pts[i].x + u.x * cs + v.x * sn,
      pts[i].y + u.y * cs + v.y * sn,
      pts[i].z + u.z * cs + v.z * sn,
    ]);
  }
  rings.push(ring);
}

const rope = [];
for (let i = 0; i < N; i++) {
  for (let j = 0; j < 3; j++) {
    const k = (j + 1) % 3;

    quad(rope, rings[i][j], rings[i][k], rings[i + 1][k], rings[i + 1][j]);
  }
}

add(posGeo(rope), CRUST);

const FACE_CAM = new THREE.Quaternion().setFromUnitVectors(
  new THREE.Vector3(1, 1, 1).normalize(), new THREE.Vector3(0, 0, 1));
[[4, 0.7], [8, 1.4], [11, 2.3], [16, 3.1]].forEach(([i, spin]) => {
  const p = pts[i], r = radiusAt(i / N);
  const g = new THREE.TetrahedronGeometry(0.0080);
  g.applyQuaternion(FACE_CAM);
  g.rotateZ(spin);
  g.translate(p.x, p.y, p.z + r * 0.60);
  add(g, SALT);
});

export function createAsset() {
  const group = new THREE.Group();
  group.name = 'pretzel';
  const mesh = finish(parts);
  mesh.name = 'pretzel_body';
  group.add(mesh);

  const box = new THREE.Box3().setFromObject(group);
  const c = box.getCenter(new THREE.Vector3());
  mesh.position.set(-c.x, -box.min.y, -c.z);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
