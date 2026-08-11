/*
 * Sword
 * https://polyfork.dev/asset/sword-11907e
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './sword-11907e.mjs';
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
 * SPECS  82 triangles, 1 material, 0.24 x 0.93 x 0.05 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

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

const STEEL = '#cdd6df';
const GOLD  = '#c79a3a';
const LEATH = '#3a2416';

const POMMEL_R = 0.032;
const GRIP_LEN = 0.17;
const GUARD_H  = 0.036;
const BLADE_LEN = 0.70;

const gripY0 = POMMEL_R * 1.2;
const gripYc = gripY0 + GRIP_LEN / 2;
const guardYc = gripY0 + GRIP_LEN + GUARD_H / 2;
const bladeY0 = guardYc + GUARD_H / 2 - 0.006;

add(new THREE.IcosahedronGeometry(POMMEL_R, 0).translate(0, POMMEL_R, 0), GOLD);

add(new THREE.CylinderGeometry(0.021, 0.023, GRIP_LEN, 6).translate(0, gripYc, 0), LEATH);

add(new THREE.BoxGeometry(0.24, GUARD_H, 0.05).translate(0, guardYc, 0), GOLD);

add(new THREE.BoxGeometry(0.055, 0.03, 0.055).translate(0, guardYc + GUARD_H / 2 + 0.012, 0), GOLD);

(function blade() {
  const yb = bladeY0;
  const ys = yb + BLADE_LEN * 0.72;
  const yt = yb + BLADE_LEN;
  const wb = 0.05, tb = 0.014;
  const ws = 0.042, ts = 0.012;

  const ring = (y, w, t) => [
    [ w, y, 0], [0, y, -t], [-w, y, 0], [0, y,  t],
  ];
  const base = ring(yb, wb, tb);
  const sh   = ring(ys, ws, ts);
  const tip  = [0, yt, 0];

  const pos = [];

  for (let i = 0; i < 4; i++) {
    const j = (i + 1) % 4;
    quad(pos, base[i], base[j], sh[j], sh[i]);
  }

  for (let i = 0; i < 4; i++) {
    const j = (i + 1) % 4;
    tri(pos, sh[i], sh[j], tip);
  }

  quad(pos, base[0], base[3], base[2], base[1]);
  add(posGeo(pos), STEEL);
})();

export function createAsset() {
  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];
