/*
 * Avocado
 * https://polyfork.dev/asset/avocado-85f504
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './avocado-85f504.mjs';
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
 * SPECS  116 triangles, 1 material, 0.09 x 0.13 x 0.07 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

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

const SKIN  = 0x2e5019;
const FLESH = 0xd8e39a;
const PIT   = 0x8a5a2e;

const H = 0.13;
const PROF = [
  [0.00, 0.000],
  [0.12, 0.030],
  [0.28, 0.043],
  [0.45, 0.047],
  [0.62, 0.043],
  [0.78, 0.032],
  [1.00, 0.000],
];
const pts = PROF.map(([t, r]) => new THREE.Vector2(r, t * H));

export function createAsset() {
  const g = new THREE.Group();
  const parts = [];
  const add = (geo, c) => parts.push({ g: geo, c });

  add(new THREE.LatheGeometry(pts, 6, Math.PI / 2, Math.PI), SKIN);

  const facePear = (scale, z) => {
    const out = [];
    const cx = 0, cy = 0.45 * H;
    const s = (x, y) => [cx + (x - cx) * scale, cy + (y - cy) * scale, z];
    for (let i = 0; i < PROF.length - 1; i++) {
      const y0 = PROF[i][0] * H,   r0 = PROF[i][1];
      const y1 = PROF[i+1][0] * H, r1 = PROF[i+1][1];
      quad(out, s(-r0, y0), s(r0, y0), s(r1, y1), s(-r1, y1));
    }
    return posGeo(out);
  };
  add(facePear(1.00, 0.0000), SKIN);
  add(facePear(0.86, 0.0015), FLESH);

  add(new THREE.IcosahedronGeometry(0.022, 0).translate(0, 0.42 * H, 0.008), PIT);

  g.add(finish(parts));
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
