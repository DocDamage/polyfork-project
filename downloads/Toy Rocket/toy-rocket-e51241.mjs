/*
 * Toy Rocket
 * https://polyfork.dev/asset/toy-rocket-e51241
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './toy-rocket-e51241.mjs';
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
 *   colorway     choice  'mint-cream'   'mint-cream' | 'red-white' | 'navy-gold' | 'coral-teal' | 'moon-mono'
 *   body         color   '#f2eddf'      any hex or THREE.Color
 *   nose         color   '#a5dfc2'      any hex or THREE.Color
 *   fin          color   '#f2eddf'      any hex or THREE.Color
 *   pod          color   '#f2eddf'      any hex or THREE.Color
 *   strut        color   '#a5dfc2'      any hex or THREE.Color
 *   ring         color   '#9ad9b8'      any hex or THREE.Color
 *   panel        color   '#8fd3b4'      any hex or THREE.Color
 *   tallness     range   1              0.82 to 1.22
 *   roundness    range   0.75           0 to 1
 *   fins         choice  '3'            '3' | '4' | '6'
 *   portholes    range   2              1 to 4
 *   boosterRing  toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/toy-rocket-e51241-params.json
 *
 * SPECS  618 triangles, 1 material, 0.35 x 0.55 x 0.31 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'mint-cream': { body: 0xF2EDDF, fin: 0xF2EDDF, pod: 0xF2EDDF, nose: 0xA5DFC2, strut: 0xA5DFC2, ring: 0x9AD9B8, panel: 0x8FD3B4, rim: 0xEDE7D6, glass: 0x3C4147, nozzle: 0x464B51 },
  'red-white':  { body: 0xF5F2EA, fin: 0xF5F2EA, pod: 0xF5F2EA, nose: 0xD64541, strut: 0xD64541, ring: 0xC93F3C, panel: 0xD64541, rim: 0xEAE4D6, glass: 0x33383E, nozzle: 0x40454B },
  'navy-gold':  { body: 0xEFEAE0, fin: 0xEFEAE0, pod: 0xEFEAE0, nose: 0x2E4057, strut: 0x2E4057, ring: 0xE0A93E, panel: 0x2E4057, rim: 0xE6E0D2, glass: 0x262B31, nozzle: 0x33383F },
  'coral-teal': { body: 0xF6F1E7, fin: 0xF6F1E7, pod: 0xF6F1E7, nose: 0xFF7E67, strut: 0xFF7E67, ring: 0x2E9C9C, panel: 0x2E9C9C, rim: 0xEEE8DA, glass: 0x343A40, nozzle: 0x41474D },
  'moon-mono':  { body: 0xE8E8E8, fin: 0xE8E8E8, pod: 0xE8E8E8, nose: 0xB9BEC2, strut: 0xB9BEC2, ring: 0x6E7478, panel: 0x9AA0A4, rim: 0xDFDFDF, glass: 0x33373B, nozzle: 0x3E4246 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: { type: 'choice', default: 'mint-cream', label: 'Colorway',
              options: ['mint-cream', 'red-white', 'navy-gold', 'coral-teal', 'moon-mono'],
              describe: 'curated paint scheme; sets every zone albedo (mint/cream retro, red/white classic, navy/gold, coral/teal toy, monochrome moon)' },
  body: { type: 'color', default: '#f2eddf', label: 'Body',
          describe: 'albedo of the barrel, fins and thruster pods (the cream shell)' },
  nose: { type: 'color', default: '#a5dfc2', label: 'Nose cone',
          describe: 'albedo of the nose cone' },
  fin: { type: 'color', default: '#f2eddf', label: 'Fins',
         describe: 'albedo of the landing fin plates' },
  pod: { type: 'color', default: '#f2eddf', label: 'Thruster pods',
         describe: 'albedo of the thruster pod tubes around the collar' },
  strut: { type: 'color', default: '#a5dfc2', label: 'Struts',
           describe: 'albedo of the strut blades hanging between the fins' },
  ring: { type: 'color', default: '#9ad9b8', label: 'Booster ring',
          describe: 'albedo of the accent collar around the lower body' },
  panel: { type: 'color', default: '#8fd3b4', label: 'Fin panels',
           describe: 'albedo of the inset panels on both faces of every fin' },
  tallness: { type: 'range', default: 1.0, min: 0.82, max: 1.22, label: 'Tallness', icon: '↕️', affects: 'geometry',
              describe: 'vertical stretch of body barrel and nose cone; 0.82 stubby toy, 1.22 slender rocket. Fins and stance unchanged' },
  roundness: { type: 'range', default: 0.75, min: 0, max: 1, label: 'Body roundness', icon: '⭕', affects: 'geometry',
              describe: 'cross-section facet count of barrel, cone, collar and belly: 0 = chunky cubical 4-sided, 0.75 = 10 facets, 1 = fully round 12 facets' },
  fins: { type: 'choice', default: '3', label: 'Fin count', icon: '📐', affects: 'geometry',
          options: ['3', '4', '6'],
          describe: 'number of landing fins the rocket stands on, evenly spaced around the base; strut blades between fins follow the same count' },
  portholes: { type: 'range', default: 2, min: 1, max: 4, label: 'Portholes', icon: '🪟', affects: 'geometry',
              describe: 'rounded porthole windows on the upper barrel, evenly spaced and snapped to facet centers (integer count 1-4)' },
  boosterRing: { type: 'toggle', default: true, label: 'Booster ring', icon: '💍', affects: 'geometry',
              describe: 'the wide accent collar with thruster pods around the lower body; off = clean barrel (pods stay, mounted on the barrel)' },
};

export const rig = {};
export const detach = [];

export const night = {};

const ZONE_KEYS = ['body', 'fin', 'pod', 'nose', 'strut', 'ring', 'panel', 'rim', 'glass', 'nozzle'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['mint-cream'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.body) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

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
function finish() {
  const merged = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function lathe(profile, sides) {
  let p = profile.slice();
  const closed = p.length > 2 && p[0][0] === p[p.length - 1][0] && p[0][1] === p[p.length - 1][1];
  if (closed) {
    let area = 0;
    for (let i = 0; i < p.length - 1; i++) area += p[i][0] * p[i + 1][1] - p[i + 1][0] * p[i][1];
    if (area < 0) p.reverse();
  } else if (p[p.length - 1][1] < p[0][1]) {
    p.reverse();
  }
  const pts = p.map(([r, y]) => new THREE.Vector2(r, y));
  return new THREE.LatheGeometry(pts, sides, -Math.PI / sides, Math.PI * 2);
}

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function flatPanel(points, z, flip = false) {
  const cx = points.reduce((s, p) => s + p[0], 0) / points.length;
  const cy = points.reduce((s, p) => s + p[1], 0) / points.length;
  const pos = [];
  for (let i = 0; i < points.length; i++) {
    const a = points[i], b = points[(i + 1) % points.length];
    if (flip) tri(pos, [cx, cy, z], [b[0], b[1], z], [a[0], a[1], z]);
    else tri(pos, [cx, cy, z], [a[0], a[1], z], [b[0], b[1], z]);
  }
  return posGeo(pos);
}

function openTopBox(w, h, d) {
  const g = new THREE.BoxGeometry(w, h, d);
  const idx = g.getIndex().array;
  g.setIndex([...idx.slice(0, 12), ...idx.slice(18)]);
  return g;
}

function roundedRect(w, h, r) {
  const s = new THREE.Shape(), hw = w / 2, hh = h / 2;
  s.moveTo(-hw + r, -hh);
  s.lineTo(hw - r, -hh); s.absarc(hw - r, -hh + r, r, -Math.PI / 2, 0);
  s.lineTo(hw, hh - r); s.absarc(hw - r, hh - r, r, 0, Math.PI / 2);
  s.lineTo(-hw + r, hh); s.absarc(-hw + r, hh - r, r, Math.PI / 2, Math.PI);
  s.lineTo(-hw, -hh + r); s.absarc(-hw + r, -hh + r, r, Math.PI, Math.PI * 1.5);
  return s;
}

const DEFAULTS = { colorway: 'mint-cream', tallness: 1, roundness: 0.75, fins: '3', portholes: 2, boosterRing: true };

export function createAsset(opts = {}) {
  parts.length = 0;
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const tall = clamp(num(o.tallness, 1), 0.82, 1.22);
  const nF = [3, 4, 6].includes(parseInt(o.fins, 10)) ? parseInt(o.fins, 10) : 3;

  const m = Math.max(2, Math.min(2 + Math.round(clamp(num(o.roundness, 0.75), 0, 1) * 2),
                                 Math.floor(18 / nF)));
  const N = nF * m;
  const nW = Math.round(clamp(num(o.portholes, 2), 1, 4));
  const ringOn = !(o.boosterRing === false || o.boosterRing === 'false' || o.boosterRing === 0);

  const R = 0.088;
  const Y0 = 0.14;
  const bodyH = 0.215 * tall;
  const noseH = 0.19 * tall;
  const yB1 = Y0 + bodyH;
  const apo = R * Math.cos(Math.PI / N);

  const step = (2 * Math.PI) / N;
  const snap = (a) => Math.round(a / step) * step;

  const finFacets = Array.from({ length: nF }, (_, k) => k * m);
  const strutFacets = finFacets.map((f) => (f + Math.floor(m / 2)) % N);
  const taken = new Set([...finFacets, ...strutFacets]);
  const freeFacets = [];
  for (let f = 0; f < N; f++) if (!taken.has(f)) freeFacets.push(f);
  const ang = (f) => f * step;

  const body = new THREE.CylinderGeometry(R, R, bodyH, N, 1, true, -Math.PI / N, Math.PI * 2);
  body.translate(0, Y0 + bodyH / 2, 0);
  add(body, C.body);

  add(lathe([[R, yB1], [R * 0.90, yB1 + noseH * 0.28], [R * 0.70, yB1 + noseH * 0.58],
             [R * 0.40, yB1 + noseH * 0.84], [0.004, yB1 + noseH]], N), C.nose);
  add(new THREE.CircleGeometry(0.004, N).rotateX(-Math.PI / 2).translate(0, yB1 + noseH, 0), C.nose);

  add(lathe([[R, Y0], [R * 0.68, 0.085], [R * 0.30, 0.050], [0.004, 0.042]], N), C.body);
  add(new THREE.CircleGeometry(0.004, N).rotateX(Math.PI / 2).translate(0, 0.042, 0), C.body);

  if (ringOn) {
    add(lathe([[R * 0.90, 0.141], [R * 1.17, 0.165], [R * 0.90, 0.190]], N), C.ring);
  }

  const podFacets = freeFacets.slice(0, nF * 2);
  for (let i = 0; i < podFacets.length; i++) {
    const a = ang(podFacets[i]);
    const tube = new THREE.CylinderGeometry(0.017, 0.017, 0.036, 6, 1, true);
    tube.rotateZ(-Math.PI / 2);
    tube.translate(0.100, 0.165, 0);
    tube.rotateY(a - Math.PI / 2);
    add(tube, C.pod);
    const dot = new THREE.CircleGeometry(0.0168, 6);
    dot.rotateY(Math.PI / 2);
    dot.translate(0.118, 0.165, 0);
    dot.rotateY(a - Math.PI / 2);
    add(dot, C.nozzle);
  }

  const B = 0.0035;
  const finShape = new THREE.Shape();
  finShape.moveTo(0.078, 0.160 - B);
  finShape.lineTo(0.080, 0.110);
  finShape.lineTo(0.128 + B, 0 + B);
  finShape.lineTo(0.195 - B, 0 + B);
  finShape.lineTo(0.150 - B, 0.140 - B);
  finShape.closePath();
  const finPlate = new THREE.ExtrudeGeometry(finShape, {
    depth: 0.025, bevelEnabled: true, bevelThickness: B, bevelSize: B, bevelSegments: 1,
  });
  finPlate.translate(0, 0, -0.0125);

  const cx = 0.1262, cy = 0.082, s = 0.72;
  const panelPts = [[0.078, 0.160], [0.080, 0.110], [0.128, 0], [0.195, 0], [0.150, 0.140]]
    .map(([x, y]) => [cx + (x - cx) * s, cy + (y - cy) * s]);
  for (let k = 0; k < nF; k++) {
    const a = ang(finFacets[k]);
    add(finPlate.clone().rotateY(a - Math.PI / 2), C.fin);
    add(flatPanel(panelPts, 0.0175).rotateY(a - Math.PI / 2), C.panel);
    add(flatPanel(panelPts, -0.0175, true).rotateY(a - Math.PI / 2), C.panel);
  }

  for (let k = 0; k < nF; k++) {
    const a = ang(strutFacets[k]);
    const strut = openTopBox(0.034, 0.090, 0.016);
    strut.translate(0, 0.100, 0.062);
    strut.rotateY(a);
    add(strut, C.strut);
  }

  const wY = yB1 - 0.062;

  const frameShape = roundedRect(0.050, 0.080, 0.014);
  frameShape.holes.push(roundedRect(0.032, 0.060, 0.009));
  const frameGeo = new THREE.ShapeGeometry(frameShape, 1);
  const glassGeo = new THREE.ShapeGeometry(roundedRect(0.038, 0.068, 0.010), 1);
  for (let i = 0; i < nW; i++) {
    const sa = snap((2 * Math.PI * i) / nW);
    add(frameGeo.clone().translate(0, 0, apo + 0.0010).rotateY(sa), C.rim);
    add(glassGeo.clone().translate(0, 0, apo + 0.0003).rotateY(sa), C.glass);
  }

  for (let i = parts.length - nW * 2; i < parts.length; i++) parts[i].g.translate(0, wY, 0);

  const g = new THREE.Group();
  g.name = 'toy-rocket';
  g.add(finish());
  return g;
}
export default createAsset;
