/*
 * Pear
 * https://polyfork.dev/asset/pear-6171b0
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './pear-6171b0.mjs';
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
 * SPECS  116 triangles, 1 material, 0.11 x 0.17 x 0.11 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const BODY = 0xb9cf3c;
const STEM = 0x6a4526;
const LEAF = 0x4c8b2b;

const SEG = 8;

const PROFILE = [
  [0.000, 0.000],
  [0.034, 0.010],
  [0.055, 0.040],
  [0.050, 0.066],
  [0.030, 0.094],
  [0.019, 0.118],
  [0.000, 0.134],
];

const parts = [];
const add = (g, c) => parts.push({ g, c });

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

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

export function createAsset() {

  const pts = PROFILE.map(([r, y]) => new THREE.Vector2(r, y));
  add(new THREE.LatheGeometry(pts, SEG), BODY);

  const stem = new THREE.CylinderGeometry(0.008, 0.010, 0.034, 3);
  stem.rotateZ(-0.22);
  stem.rotateY(0.4);
  stem.translate(0.006, 0.147, 0.001);
  add(stem, STEM);

  const P0 = new THREE.Vector3(0.014, 0.126, 0.006);
  const P1 = new THREE.Vector3(0.058, 0.172, 0.024);
  const u = P1.clone().sub(P0).normalize();
  const side = new THREE.Vector3().crossVectors(u, new THREE.Vector3(0, 1, 0)).normalize();
  const up2 = new THREE.Vector3().crossVectors(side, u).normalize();
  const tilt = 30 * Math.PI / 180;
  const w = side.clone().multiplyScalar(Math.cos(tilt))
    .addScaledVector(up2, Math.sin(tilt)).normalize();
  const n = new THREE.Vector3().crossVectors(u, w).normalize();
  const mid = P0.clone().lerp(P1, 0.35);
  const W = 0.017, TH = 0.004;
  const ring = [
    P0.toArray(),
    mid.clone().addScaledVector(w, W).toArray(),
    P1.toArray(),
    mid.clone().addScaledVector(w, -W).toArray(),
  ];
  const apexA = mid.clone().addScaledVector(n, TH).toArray();
  const apexB = mid.clone().addScaledVector(n, -TH).toArray();
  const leaf = [];
  for (let i = 0; i < 4; i++) {
    const a = ring[i], b = ring[(i + 1) % 4];
    tri(leaf, apexA, a, b);
    tri(leaf, apexB, b, a);
  }
  add(posGeo(leaf), LEAF);

  const mesh = finish(parts);
  parts.length = 0;

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  const group = new THREE.Group();
  group.name = 'pear';
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
