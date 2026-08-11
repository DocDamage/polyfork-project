/*
 * Coin Pouch
 * https://polyfork.dev/asset/coin-pouch-be4dd8
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './coin-pouch-be4dd8.mjs';
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
 * SPECS  340 triangles, 1 material, 0.29 x 0.34 x 0.29 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const LEATHER = '#8c6a4a';
const CORD    = '#6f4e37';
const TAN     = '#b89b72';
const GOLD    = '#c1962c';

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

function tri(o, a, b, c) { o.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(o, a, b, c, d) { tri(o, a, b, c); tri(o, a, c, d); }
function posGeo(p) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(p, 3));
  return g;
}

function loft(rings, seg, { phase = 0, capBottom = false, capTop = false } = {}) {
  const P = (j, i) => {
    const a = phase + (i % seg) * Math.PI * 2 / seg;
    return [Math.sin(a) * rings[j][0], rings[j][1], Math.cos(a) * rings[j][0]];
  };
  const out = [];
  for (let j = 0; j + 1 < rings.length; j++)
    for (let i = 0; i < seg; i++) quad(out, P(j, i), P(j, i + 1), P(j + 1, i + 1), P(j + 1, i));
  if (capBottom) {
    const c = [0, rings[0][1], 0];
    for (let i = 0; i < seg; i++) tri(out, c, P(0, i + 1), P(0, i));
  }
  if (capTop) {
    const j = rings.length - 1, c = [0, rings[j][1], 0];
    for (let i = 0; i < seg; i++) tri(out, c, P(j, i), P(j, i + 1));
  }
  return posGeo(out);
}

function coin(r, t, seg = 8, capBottom = false) {
  const top = [], bot = [];
  for (let i = 0; i < seg; i++) {
    const a = (i / seg) * Math.PI * 2;
    top.push([Math.cos(a) * r, t / 2, Math.sin(a) * r]);
    bot.push([Math.cos(a) * r, -t / 2, Math.sin(a) * r]);
  }
  const out = [], c = [0, t / 2, 0];
  for (let i = 0; i < seg; i++) {
    const j = (i + 1) % seg;
    tri(out, c, top[j], top[i]);
    quad(out, top[i], top[j], bot[j], bot[i]);
  }
  if (capBottom) {
    const cb = [0, -t / 2, 0];
    for (let i = 0; i < seg; i++) tri(out, cb, bot[i], bot[(i + 1) % seg]);
  }
  return posGeo(out);
}

export function createAsset() {
  parts.length = 0;
  const SEG = 8, PH = -Math.PI / SEG;

  add(loft([[0.058, -0.230], [0.098, -0.196], [0.118, -0.158], [0.122, -0.086], [0.068, -0.030]],
    SEG, { phase: PH, capBottom: true, capTop: true }), LEATHER);

  add(loft([[0.046, -0.038], [0.050, -0.012], [0.042, 0.014]], SEG, { phase: PH }), CORD);

  const knot = new THREE.IcosahedronGeometry(0.015, 0);
  knot.translate(0.036, -0.006, 0.036);
  add(knot, CORD);

  add(loft([[0.038, 0.000], [0.080, 0.042], [0.072, 0.072]], SEG, { phase: PH }), TAN);

  add(loft([[0.090, 0.062], [0.080, 0.080], [0.060, 0.096]], SEG, { phase: PH, capTop: true }), GOLD);

  const c1 = coin(0.052, 0.017);
  c1.rotateX(0.16); c1.rotateZ(-0.12); c1.translate(0.014, 0.096, 0.014);
  add(c1, GOLD);
  const c2 = coin(0.046, 0.017);
  c2.rotateX(-0.26); c2.rotateZ(0.46); c2.translate(-0.044, 0.084, -0.018);
  add(c2, GOLD);
  const c3 = coin(0.048, 0.017);
  c3.rotateX(-0.52); c3.rotateZ(0.10); c3.translate(0.010, 0.072, 0.058);
  add(c3, GOLD);

  const c4 = coin(0.045, 0.016, 8, true);
  c4.rotateY(0.3); c4.translate(0.130, -0.222, 0.070);
  add(c4, GOLD);
  const c5 = coin(0.040, 0.016, 8, true);
  c5.rotateY(0.9); c5.translate(0.050, -0.222, 0.135);
  add(c5, GOLD);

  const merged = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();

  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'coin-pouch-mesh';

  const g = new THREE.Group();
  g.name = 'coin-pouch';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export default createAsset;
