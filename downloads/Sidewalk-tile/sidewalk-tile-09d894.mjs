/*
 * Sidewalk-tile
 * https://polyfork.dev/asset/sidewalk-tile-09d894
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './sidewalk-tile-09d894.mjs';
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
 * OPTIONS  createAsset({ ... })
 *
 *   colorway   choice  'pale-concrete' 'pale-concrete' | 'grey-concrete' | 'weathered' | 'cool-slab'
 *   paving     color   '#ddceb0'      any hex or THREE.Color
 *   substrate  color   '#898c95'      any hex or THREE.Color
 *   seamDepth  range   0.018          0.006 to 0.024
 *   slabs      range   3              2 to 5
 *
 * Every option is described in full at https://polyfork.dev/cdn/sidewalk-tile-09d894-params.json
 *
 * SPECS  308 triangles, 1 material, 4 x 0.05 x 4 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SIZE = 4.0;
const HALF = SIZE / 2;
const THICK = 0.05;
const TOP_Y = 0.0;
const BOT_Y = TOP_Y - THICK;

const SEAM_HW = 0.03;
const BAND = 0.34;
const BAND_L = HALF - BAND;

const COLORWAYS = {
  'pale-concrete': { paving: 0xddceb0, substrate: 0x898c95 },
  'grey-concrete': { paving: 0xc2c7cd, substrate: 0x676b72 },
  'weathered':     { paving: 0xc7baa6, substrate: 0x744d36 },
  'cool-slab':     { paving: 0xafb5bb, substrate: 0x4c4f57 },
};
const DEF = {
  colorway: 'pale-concrete',
  seamDepth: 0.018,
  slabs: 3,
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
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

export function createAsset(p = {}) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[DEF.colorway];
  const C = {
    paving:    p.paving    !== undefined ? p.paving    : cw.paving,
    substrate: p.substrate !== undefined ? p.substrate : cw.substrate,
  };
  const SD = Math.max(0.006, Math.min(0.024, p.seamDepth !== undefined ? p.seamDepth : DEF.seamDepth));
  const NS = Math.max(2, Math.min(5, Math.round(p.slabs !== undefined ? p.slabs : DEF.slabs)));

  const lines = [-BAND_L];
  for (let i = 1; i < NS; i++) lines.push(-BAND_L + i * (2 * BAND_L / NS));
  lines.push(BAND_L);

  const co = [-HALF];
  for (const L of lines) co.push(L - SEAM_HW, L + SEAM_HW);
  co.push(HALF);
  const N = co.length - 1;
  const even = [];
  for (let i = 0; i < N; i += 2) even.push(i);
  const GY = TOP_Y - SD;

  const top = [];
  for (const j of even) for (const i of even)
    quad(top, [co[i], TOP_Y, co[j + 1]], [co[i + 1], TOP_Y, co[j + 1]],
              [co[i + 1], TOP_Y, co[j]], [co[i], TOP_Y, co[j]]);
  for (let i = 1; i < N; i += 2)
    quad(top, [co[i], GY, HALF], [co[i + 1], GY, HALF], [co[i + 1], GY, -HALF], [co[i], GY, -HALF]);
  for (let j = 1; j < N; j += 2) for (const i of even)
    quad(top, [co[i], GY, co[j + 1]], [co[i + 1], GY, co[j + 1]],
              [co[i + 1], GY, co[j]], [co[i], GY, co[j]]);

  for (let i = 1; i < N; i += 2) for (const j of even) {
    const x0 = co[i], x1 = co[i + 1], z0 = co[j], z1 = co[j + 1];
    quad(top, [x0, GY, z1], [x0, GY, z0], [x0, TOP_Y, z0], [x0, TOP_Y, z1]);
    quad(top, [x1, GY, z0], [x1, GY, z1], [x1, TOP_Y, z1], [x1, TOP_Y, z0]);
  }
  for (let j = 1; j < N; j += 2) for (const i of even) {
    const x0 = co[i], x1 = co[i + 1], z0 = co[j], z1 = co[j + 1];
    quad(top, [x1, GY, z1], [x0, GY, z1], [x0, TOP_Y, z1], [x1, TOP_Y, z1]);
    quad(top, [x0, GY, z0], [x1, GY, z0], [x1, TOP_Y, z0], [x0, TOP_Y, z0]);
  }

  const side = [];
  quad(side, [HALF, BOT_Y, HALF], [HALF, BOT_Y, -HALF], [HALF, GY, -HALF], [HALF, GY, HALF]);
  quad(side, [-HALF, BOT_Y, -HALF], [-HALF, BOT_Y, HALF], [-HALF, GY, HALF], [-HALF, GY, -HALF]);
  quad(side, [-HALF, BOT_Y, HALF], [HALF, BOT_Y, HALF], [HALF, GY, HALF], [-HALF, GY, HALF]);
  quad(side, [HALF, BOT_Y, -HALF], [-HALF, BOT_Y, -HALF], [-HALF, GY, -HALF], [HALF, GY, -HALF]);
  for (const k of even) {
    const a = co[k], b = co[k + 1];
    quad(side, [HALF, GY, b], [HALF, GY, a], [HALF, TOP_Y, a], [HALF, TOP_Y, b]);
    quad(side, [-HALF, GY, a], [-HALF, GY, b], [-HALF, TOP_Y, b], [-HALF, TOP_Y, a]);
    quad(side, [a, GY, HALF], [b, GY, HALF], [b, TOP_Y, HALF], [a, TOP_Y, HALF]);
    quad(side, [b, GY, -HALF], [a, GY, -HALF], [a, TOP_Y, -HALF], [b, TOP_Y, -HALF]);
  }
  quad(side, [-HALF, BOT_Y, -HALF], [HALF, BOT_Y, -HALF], [HALF, BOT_Y, HALF], [-HALF, BOT_Y, HALF]);

  const g = new THREE.Group();
  g.name = 'sidewalk-tile';
  const mesh = finish([{ g: posGeo(top), c: C.paving }, { g: posGeo(side), c: C.substrate }]);
  mesh.name = 'sidewalk-surface';
  g.add(mesh);
  return g;
}

export const params = {
  colorway:   { type: 'choice', default: 'pale-concrete', label: 'Colorway',
                options: ['pale-concrete', 'grey-concrete', 'weathered', 'cool-slab'],
                describe: 'curated pavement scheme: pale-concrete is the kit default warm cream sidewalk, grey-concrete a cooler modern city pavement, weathered a tan sun-baked walk on brown base course, cool-slab a pale bluish-grey utilitarian pavement' },
  paving:     { type: 'color', default: '#ddceb0', label: 'Paving',
                describe: 'albedo of the whole poured sidewalk INCLUDING the sunken panel joints — about 95% of the visible surface. The seams read from their own recess shading, so they carry no separate colour of their own' },
  substrate:  { type: 'color', default: '#898c95', label: 'Substrate',
                describe: 'albedo of the slab cut edges and underside (the base course); keeps the tile border a crisp line against the ground' },
  seamDepth:  { type: 'range', default: 0.018, min: 0.006, max: 0.024, label: 'Seam depth',
                affects: 'geometry',
                describe: 'depth in metres of the sunken paving joints: 0.006 is a hairline control joint on fresh concrete, 0.024 a deep eroded gap that shades itself hard from any angle. Every seam runs edge to edge at every value, and the tile still butts flush because the seam notches on facing edges line up' },
  slabs:      { type: 'range', default: 3, min: 2, max: 5, step: 1, label: 'Slabs across',
                affects: 'geometry',
                describe: 'how many paving slabs divide the field inside the edge course, on BOTH axes: 2 gives a calm 2x2 of big 1.66 m slabs, 5 a fine 0.66 m flagstone grid. The 0.34 m edge course round all four sides is always there, and the grid stays square so the tile matches itself at any 90-degree rotation' },
};
export const presets = COLORWAYS;
export const rig = {};
export const detach = [];

export const night = {};
export default createAsset;
