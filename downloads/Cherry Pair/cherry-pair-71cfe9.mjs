/*
 * Cherry Pair
 * https://polyfork.dev/asset/cherry-pair-71cfe9
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './cherry-pair-71cfe9.mjs';
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
 * SPECS  118 triangles, 1 material, 0.07 x 0.08 x 0.04 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const RED   = 0xd2312f;
const STEM  = 0x467a31;
const LEAF  = 0x6fae3d;

const R      = 0.0185;
const SQUASH = 0.88;
const CX     = 0.0195;
const DZ     = 0.005;
const APEX   = new THREE.Vector3(0, 0.070, 0);

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const _u = new THREE.Vector3(), _v = new THREE.Vector3(), _n = new THREE.Vector3(), _d = new THREE.Vector3();
function tri(out, a, b, c, ref) {
  _u.subVectors(b, a); _v.subVectors(c, a); _n.crossVectors(_u, _v);
  _d.set((a.x + b.x + c.x) / 3 - ref.x, (a.y + b.y + c.y) / 3 - ref.y, (a.z + b.z + c.z) / 3 - ref.z);
  if (_n.dot(_d) < 0) { const t = b; b = c; c = t; }
  out.push(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z);
}
function quad(out, a, b, c, d, ref) { tri(out, a, b, c, ref); tri(out, a, c, d, ref); }

function berry(x, z, spin) {
  const g = new THREE.IcosahedronGeometry(R, 0).rotateY(spin).scale(1, SQUASH, 1);
  g.computeBoundingBox();
  return g.translate(x, -g.boundingBox.min.y, z);
}

function bezier(p0, p1, p2, t) {
  const s = 1 - t;
  return new THREE.Vector3(
    s * s * p0.x + 2 * s * t * p1.x + t * t * p2.x,
    s * s * p0.y + 2 * s * t * p1.y + t * t * p2.y,
    s * s * p0.z + 2 * s * t * p1.z + t * t * p2.z);
}
function stem(p0, p1, p2, radius = 0.0027, sides = 5, segs = 3) {
  const path = [];
  for (let i = 0; i <= segs; i++) path.push(bezier(p0, p1, p2, i / segs));
  const rings = path.map((p, i) => {
    const tan = new THREE.Vector3().subVectors(path[Math.min(i + 1, segs)], path[Math.max(i - 1, 0)]).normalize();
    const u = new THREE.Vector3(0, 0, 1);
    const v = new THREE.Vector3().crossVectors(tan, u).normalize();
    const ring = [];
    for (let k = 0; k < sides; k++) {
      const a = (k / sides) * Math.PI * 2;
      ring.push(new THREE.Vector3(
        p.x + Math.cos(a) * radius * u.x + Math.sin(a) * radius * v.x,
        p.y + Math.cos(a) * radius * u.y + Math.sin(a) * radius * v.y,
        p.z + Math.cos(a) * radius * u.z + Math.sin(a) * radius * v.z));
    }
    return ring;
  });
  const pos = [];
  for (let i = 0; i < segs; i++) {
    for (let k = 0; k < sides; k++) {
      const k2 = (k + 1) % sides;

      const ref = new THREE.Vector3().addVectors(path[i], path[i + 1]).multiplyScalar(0.5);
      quad(pos, rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k], ref);
    }
  }

  const top = rings[segs];
  const capRef = path[segs - 1];
  for (let k = 1; k < sides - 1; k++) tri(pos, top[0], top[k], top[k + 1], capRef);
  return posGeo(pos);
}

function leaf(len = 0.030, wid = 0.024, th = 0.0032) {
  const h = th / 2;

  const plan = [[0, 0], [len * 0.32, -wid / 2], [len, 0], [len * 0.32, wid / 2]];
  const top = plan.map(([x, z]) => new THREE.Vector3(x, h, z));
  const bot = plan.map(([x, z]) => new THREE.Vector3(x, -h, z));
  const ref = new THREE.Vector3(len * 0.4, 0, 0);
  const pos = [];
  quad(pos, top[0], top[1], top[2], top[3], ref);
  quad(pos, bot[0], bot[1], bot[2], bot[3], ref);
  for (let i = 0; i < 4; i++) {
    const j = (i + 1) % 4;
    quad(pos, bot[i], bot[j], top[j], top[i], ref);
  }
  return posGeo(pos);
}

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

export function createAsset() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  add(berry(-CX, -DZ, Math.PI / 10), RED);
  add(berry( CX,  DZ, Math.PI / 3.3), RED);

  add(stem(new THREE.Vector3(-CX, 0.027, -DZ), new THREE.Vector3(-0.0245, 0.050, -DZ / 2), APEX), STEM);
  add(stem(new THREE.Vector3( CX, 0.027,  DZ), new THREE.Vector3( 0.0245, 0.050,  DZ / 2), APEX), STEM);

  const lf = leaf();
  lf.rotateZ(THREE.MathUtils.degToRad(22));
  lf.rotateY(THREE.MathUtils.degToRad(40));
  lf.translate(0.001, 0.0675, -0.001);
  add(lf, LEAF);

  const group = new THREE.Group();
  group.name = 'cherry-pair';
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
