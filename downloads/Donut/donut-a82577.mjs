/*
 * Donut
 * https://polyfork.dev/asset/donut-a82577
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './donut-a82577.mjs';
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
 * SPECS  130 triangles, 1 material, 0.11 x 0.04 x 0.1 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const DOUGH = 0xbf7233;
const GLAZE = 0xf4568f;
const SPRINKLE = 0xfff6ec;

const RING = 0.038;
const TUBE = 0.017;
const SQUASH = 1.25;
const N = 10;
const M = 6;

const parts = [];
const add = (g, c) => parts.push({ g, c });

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
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

const A_OF = i => (i / N) * Math.PI * 2;
const B_OF = j => (j / M) * Math.PI * 2;
const P = (i, j) => {
  const a = A_OF(i), b = B_OF(j);
  const k = RING + TUBE * Math.cos(b);
  return [k * Math.cos(a), TUBE * SQUASH * Math.sin(b), k * Math.sin(a)];
};

const GLAZED = [0, 1];

const DRIPS = new Set([0, 4, 7]);
const glazePos = [], doughPos = [];
for (let i = 0; i < N; i++) {
  for (let j = 0; j < M; j++) {
    const glazed = GLAZED.includes(j) || (j === 5 && DRIPS.has(i));

    quad(glazed ? glazePos : doughPos,
      P(i, j), P(i, (j + 1) % M), P(i + 1, (j + 1) % M), P(i + 1, j));
  }
}

function signedVolume(pos) {
  let v = 0;
  for (let t = 0; t < pos.length; t += 9) {
    const [ax,ay,az,bx,by,bz,cx,cy,cz] = pos.slice(t, t + 9);
    v += (ax * (by * cz - bz * cy) - ay * (bx * cz - bz * cx) + az * (bx * cy - by * cx)) / 6;
  }
  return v;
}
if (signedVolume(glazePos.concat(doughPos)) <= 0) throw new Error('torus wound inside-out');

add(posGeo(doughPos), DOUGH);
add(posGeo(glazePos), GLAZE);

const TOP_Y = TUBE * SQUASH * Math.sin(Math.PI / 3);
const SPRINKLES = [
  [0.03, 0.000, 0.20], [0.23, 0.004, 0.31], [0.44, -0.004, 0.25],
  [0.63, 0.003, 0.34], [0.83, -0.003, 0.17],
];
const sprinklePos = [];
for (const [t, dr, yaw] of SPRINKLES) {
  const a = t * Math.PI * 2, r = RING + dr;
  const cx = Math.cos(a) * r, cz = Math.sin(a) * r;
  const y = TOP_Y + 0.0005;
  const ang = a + yaw * Math.PI * 2;
  const ux = Math.cos(ang) * 0.0075, uz = Math.sin(ang) * 0.0075;
  const vx = -Math.sin(ang) * 0.0022, vz = Math.cos(ang) * 0.0022;

  quad(sprinklePos,
    [cx - ux + vx, y, cz - uz + vz], [cx + ux + vx, y, cz + uz + vz],
    [cx + ux - vx, y, cz + uz - vz], [cx - ux - vx, y, cz - uz - vz]);
}
add(posGeo(sprinklePos), SPRINKLE);

export function createAsset() {
  const g = new THREE.Group();
  const mesh = finish(parts);
  mesh.geometry.translate(0, TOP_Y, 0);
  mesh.name = 'donut';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
