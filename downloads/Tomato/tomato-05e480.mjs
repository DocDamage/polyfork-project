/*
 * Tomato
 * https://polyfork.dev/asset/tomato-05e480
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './tomato-05e480.mjs';
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
 * SPECS  107 triangles, 1 material, 0.07 x 0.06 x 0.07 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const RED   = '#d42a1c';
const GREEN = '#57a52f';
const STEM  = '#3a6b22';

const R      = 0.038;
const SQUASH = 0.76;
const DIMPLE = 0.0045;

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

function body() {
  const g = new THREE.SphereGeometry(R, 8, 5);
  const p = g.attributes.position;
  const yTop = R;
  for (let i = 0; i < p.count; i++) {
    const y = p.getY(i);
    const isPole = y > yTop - 1e-5;
    p.setY(i, y * SQUASH - (isPole ? DIMPLE : 0));
  }
  p.needsUpdate = true;
  return g;
}

const surfaceY = (d) => SQUASH * Math.sqrt(Math.max(0, R * R - d * d));

const TOP = R * SQUASH - DIMPLE;

const LEAF_T = 0.0015;
function calyx() {
  const pos = [];
  const N = 5;
  const P = (r, da, y, a) => [Math.cos(a + da) * r, y, Math.sin(a + da) * r];
  const below = (p) => [p[0], p[1] - LEAF_T, p[2]];
  for (let i = 0; i < N; i++) {
    const a = (i / N) * Math.PI * 2;
    const b0 = P(0.008, -0.60, TOP + 0.0020, a);
    const b1 = P(0.008,  0.60, TOP + 0.0020, a);
    const m0 = P(0.021, -0.42, surfaceY(0.021) + 0.0035, a);
    const m1 = P(0.021,  0.42, surfaceY(0.021) + 0.0035, a);

    const t  = P(0.035,  0,    surfaceY(0.035) + 0.0025, a);

    tri(pos, b0, b1, m1); tri(pos, b0, m1, m0); tri(pos, m0, m1, t);

    const u0 = below(b0), u1 = below(b1), v0 = below(m0), v1 = below(m1), w = below(t);
    tri(pos, u1, u0, v1); tri(pos, v1, u0, v0); tri(pos, v1, v0, w);
  }
  return posGeo(pos);
}

function stem() {
  const pos = [];
  const N = 5, r0 = 0.0085, r1 = 0.0065;
  const y0 = TOP - 0.001, y1 = TOP + 0.011;
  const ring = (r, y) => Array.from({ length: N }, (_, i) => {
    const a = (i / N) * Math.PI * 2 + 0.3;
    return [Math.cos(a) * r, y, Math.sin(a) * r];
  });
  const lo = ring(r0, y0), hi = ring(r1, y1);

  for (let i = 0; i < N; i++) {
    const j = (i + 1) % N;
    tri(pos, hi[j], lo[j], lo[i]);
    tri(pos, hi[j], lo[i], hi[i]);
  }
  for (let i = 1; i < N - 1; i++) tri(pos, hi[0], hi[i + 1], hi[i]);
  return posGeo(pos);
}

export function createAsset() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });
  add(body(), RED);
  add(calyx(), GREEN);
  add(stem(), STEM);

  const mesh = finish(parts);
  mesh.geometry.translate(0, R * SQUASH, 0);
  mesh.castShadow = true;
  mesh.receiveShadow = true;

  const group = new THREE.Group();
  group.name = 'tomato';
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
