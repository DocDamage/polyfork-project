/*
 * Torii Gate
 * https://polyfork.dev/asset/torii-gate-402f30
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './torii-gate-402f30.mjs';
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
 *   colorway    choice  'vermilion-shrine' 'vermilion-shrine' | 'weathered-cypress' | 'stone-grey'
 *   post        color   '#B5462F'      any hex or THREE.Color
 *   beam        color   '#D6452F'      any hex or THREE.Color
 *   cap         color   '#2E3134'      any hex or THREE.Color
 *   collar      color   '#3C4145'      any hex or THREE.Color
 *   stone       color   '#C7CBCC'      any hex or THREE.Color
 *   gateWidth   range   2.6            2.1 to 3.4
 *   sori        range   1              0.15 to 1.7
 *   postFacets  range   8              6 to 12
 *
 * Every option is described in full at https://polyfork.dev/cdn/torii-gate-402f30-params.json
 *
 * SPECS  440 triangles, 1 material, 2.6 x 3.19 x 0.55 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function slab(w, h, d, x, y, z, skip = {}) {
  const X0 = x - w / 2, X1 = x + w / 2, Y0 = y - h / 2, Y1 = y + h / 2, Z0 = z - d / 2, Z1 = z + d / 2;
  const p = (a, b, c) => [a, b, c];
  const pos = [];
  if (!skip.zp) quad(pos, p(X0, Y0, Z1), p(X1, Y0, Z1), p(X1, Y1, Z1), p(X0, Y1, Z1));
  if (!skip.zn) quad(pos, p(X1, Y0, Z0), p(X0, Y0, Z0), p(X0, Y1, Z0), p(X1, Y1, Z0));
  if (!skip.xp) quad(pos, p(X1, Y0, Z1), p(X1, Y0, Z0), p(X1, Y1, Z0), p(X1, Y1, Z1));
  if (!skip.xn) quad(pos, p(X0, Y0, Z0), p(X0, Y0, Z1), p(X0, Y1, Z1), p(X0, Y1, Z0));
  if (!skip.yp) quad(pos, p(X0, Y1, Z1), p(X1, Y1, Z1), p(X1, Y1, Z0), p(X0, Y1, Z0));
  if (!skip.yn) quad(pos, p(X0, Y0, Z0), p(X1, Y0, Z0), p(X1, Y0, Z1), p(X0, Y0, Z1));
  return posGeo(pos);
}

function prism(sides, y0, y1, r0, r1, x0, x1, z, capTop, capBottom) {
  const ang = (i) => Math.PI / 2 + ((2 * i + 1) * Math.PI) / sides;
  const b = [], t = [];
  for (let i = 0; i < sides; i++) {
    const a = ang(i);
    b.push([x0 + Math.cos(a) * r0, y0, z + Math.sin(a) * r0]);
    t.push([x1 + Math.cos(a) * r1, y1, z + Math.sin(a) * r1]);
  }
  const pos = [];
  for (let i = 0; i < sides; i++) {
    const j = (i + 1) % sides;
    quad(pos, b[i], t[i], t[j], b[j]);
  }
  if (capTop) for (let i = 1; i < sides - 1; i++) tri(pos, t[0], t[i + 1], t[i]);
  if (capBottom) for (let i = 1; i < sides - 1; i++) tri(pos, b[0], b[i], b[i + 1]);
  return posGeo(pos);
}

function sweep(profile, stations, skipEdge = -1) {
  const n = profile.length;
  const rings = stations.map((s) => {
    const c = Math.cos(s.phi), sn = Math.sin(s.phi);
    return profile.map(([pz, py]) => [s.x - py * sn, s.y + py * c, pz]);
  });
  const pos = [];
  for (let k = 0; k < rings.length - 1; k++) {
    const A = rings[k], B = rings[k + 1];
    for (let i = 0; i < n; i++) {
      if (i === skipEdge) continue;
      const j = (i + 1) % n;
      quad(pos, A[i], B[i], B[j], A[j]);
    }
  }
  const A = rings[0], B = rings[rings.length - 1];
  for (let i = 1; i < n - 1; i++) {
    tri(pos, A[0], A[i], A[i + 1]);
    tri(pos, B[0], B[i + 1], B[i]);
  }
  return posGeo(pos);
}

const ZONES = ['post', 'beam', 'cap', 'collar', 'stone'];

export const presets = {
  'vermilion-shrine': { post: '#B5462F', beam: '#D6452F', cap: '#2E3134', collar: '#3C4145', stone: '#C7CBCC' },
  'weathered-cypress': { post: '#8C7355', beam: '#B9A88C', cap: '#42352A', collar: '#63503C', stone: '#A9AFB4' },
  'stone-grey': { post: '#8A9197', beam: '#A9AFB4', cap: '#2E3134', collar: '#4E5459', stone: '#E4E2DC' },
};

export const params = {
  colorway: {
    type: 'choice', default: 'vermilion-shrine', label: 'Colorway', affects: 'colors',
    options: ['vermilion-shrine', 'weathered-cypress', 'stone-grey'],
    describe: 'whole-gate scheme. vermilion-shrine is the painted shinto red with a near-black cap; ' +
      'weathered-cypress is unpainted brown timber on grey stone; stone-grey is a pale unpainted/ash gate.',
  },
  post: {
    type: 'color', default: '#B5462F', label: 'Post', affects: 'colors',
    describe: 'albedo of the two tapered uprights above their black base wrap; the darker of the two reds.',
  },
  beam: {
    type: 'color', default: '#D6452F', label: 'Beam timber', affects: 'colors',
    describe: 'albedo of every horizontal timber — the curved shimaki under the cap, the straight nuki tie ' +
      'beam, the post-head blocks, the centre strut and the wedges. One value step lighter than the posts.',
  },
  cap: {
    type: 'color', default: '#2E3134', label: 'Cap beam', affects: 'colors',
    describe: 'albedo of the kasagi, the dark curved crown beam that overhangs both ends. Near-black slate.',
  },
  collar: {
    type: 'color', default: '#3C4145', label: 'Base wrap', affects: 'colors',
    describe: 'albedo of the lacquered black band on the bottom of each post, between stone pad and post.',
  },
  stone: {
    type: 'color', default: '#C7CBCC', label: 'Stone pad', affects: 'colors',
    describe: 'albedo of the two octagonal stone footings. Pale dry granite.',
  },

  gateWidth: {
    type: 'range', default: 2.6, min: 2.1, max: 3.4, label: 'Gate width', affects: 'geometry',
    describe: 'overall width of the gate in metres, REBUILT not scaled: post spacing, tie-beam length ' +
      'and lintel overhang all re-solve, and the curved lintel re-segments at a constant ~0.30 m station ' +
      'pitch so the triangle count moves with the width. 2.1 is a narrow alley shrine gate, 3.4 a broad ' +
      'approach gate. Height, member sections and the stone pads stay put at every value.',
  },
  sori: {
    type: 'range', default: 1.0, min: 0.15, max: 1.7, label: 'Lintel curve', affects: 'geometry',
    describe: 'how far the crown beam sweeps up toward its ends, as a multiple of the default 0.25 m rise. ' +
      '0.15 is an almost dead-straight shinmei-style lintel; 1.7 is a strongly upturned myojin sweep with ' +
      'the tips well above the centre. Also raises total height (2.99 m to 3.35 m).',
  },
  postFacets: {
    type: 'range', default: 8, min: 6, max: 12, label: 'Post facets', affects: 'geometry',
    describe: 'facet count of the posts, base wraps and stone pads, snapped to an even number so the ' +
      'footings rest on a flat. 6 reads as a chunky hexagonal hewn post, 12 as an almost smooth turned one.',
  },
};

function resolveColors(p) {
  const cw = presets[p.colorway] || presets[params.colorway.default];
  const C = {};
  for (const z of ZONES) C[z] = (p[z] != null ? p[z] : cw[z]);
  return C;
}

export function createAsset(p = {}) {
  const C = resolveColors(p);
  const SPAN = Math.min(3.4, Math.max(2.1, p.gateWidth != null ? +p.gateWidth : params.gateWidth.default));
  const SORI = Math.min(1.7, Math.max(0.15, p.sori != null ? +p.sori : params.sori.default));
  let SIDES = Math.round(p.postFacets != null ? +p.postFacets : params.postFacets.default);
  SIDES = Math.min(12, Math.max(6, SIDES - (SIDES % 2)));

  const PAD_H = 0.11, PAD_R0 = 0.30, PAD_R1 = 0.275;
  const WRAP_TOP = 0.50;
  const FOOT_Y = 0.06;
  const POST_TOP = 2.56, POST_R0 = 0.158, POST_R1 = 0.122;
  const DAIWA_BOT = 2.52, DAIWA_W = 0.32, DAIWA_D = 0.34;
  const NUKI_Y = 2.10, NUKI_H = 0.22, NUKI_D = 0.26, NUKI_CH = 0.045;
  const KAS_BOT = 2.79;
  const SHIM_H = 0.21, SHIM_HD = 0.15, CAP_H = 0.16, CAP_HD = 0.18;
  const RISE = 0.25 * SORI;

  const xBot = 0.300 * SPAN, xTop = 0.280 * SPAN;
  const postX = (y) => xBot + (xTop - xBot) * (y / POST_TOP);
  const postR = (y) => POST_R0 + (POST_R1 - POST_R0) * (y / POST_TOP);

  let half = SPAN / 2;
  for (let it = 0; it < 3; it++) {
    const phiEnd = Math.atan((2 * RISE) / half);
    half = SPAN / 2 - SHIM_H * Math.sin(phiEnd);
  }
  const spans = 2 * Math.max(3, Math.ceil(SPAN / 0.60));
  const stations = [];
  for (let i = 0; i <= spans; i++) {
    const x = -half + (2 * half * i) / spans;
    stations.push({ x, y: KAS_BOT + RISE * (x / half) ** 2, phi: Math.atan((2 * RISE * x) / (half * half)) });
  }
  const soffit = (x) => KAS_BOT + RISE * Math.min(1, (x / half) ** 2) - SHIM_H;

  // The cap terminates 6 mm further out along the beam than the shimaki, so the two tilted
  // end caps do not share one plane (they would z-fight).
  const CAP_PROUD = 0.006;
  const capStations = stations.map((s, i) => {
    if (i !== 0 && i !== stations.length - 1) return s;
    const out = i === 0 ? -1 : 1;
    return { x: s.x + out * CAP_PROUD * Math.cos(s.phi), y: s.y + out * CAP_PROUD * Math.sin(s.phi), phi: s.phi };
  });

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  for (const side of [1, -1]) {
    const bx = side * xBot;
    add(prism(SIDES, 0, PAD_H, PAD_R0, PAD_R1, bx, bx, 0, true, true), C.stone);
    add(prism(SIDES, FOOT_Y, WRAP_TOP, postR(FOOT_Y), postR(WRAP_TOP),
      side * postX(FOOT_Y), side * postX(WRAP_TOP), 0, false, false), C.collar);
    add(prism(SIDES, WRAP_TOP, POST_TOP, postR(WRAP_TOP), postR(POST_TOP),
      side * postX(WRAP_TOP), side * postX(POST_TOP), 0, false, false), C.post);

    const hx = side * postX(POST_TOP);
    const dTop = soffit(hx) + 0.06;
    add(slab(DAIWA_W, dTop - DAIWA_BOT, DAIWA_D, hx, (dTop + DAIWA_BOT) / 2, 0), C.beam);
  }

  const nukiHalf = 0.404 * SPAN;
  const hz = NUKI_D / 2, hy = NUKI_H / 2, ch = NUKI_CH;
  const nukiProfile = [
    [hz - ch, -hy], [hz, -hy + ch], [hz, hy - ch], [hz - ch, hy],
    [-hz + ch, hy], [-hz, hy - ch], [-hz, -hy + ch], [-hz + ch, -hy],
  ];
  add(sweep(nukiProfile, [{ x: -nukiHalf, y: NUKI_Y, phi: 0 }, { x: nukiHalf, y: NUKI_Y, phi: 0 }]), C.beam);

  for (const side of [1, -1]) {
    const wx = side * (postX(NUKI_Y + NUKI_H / 2) + 0.05);
    add(slab(0.26, 0.11, 0.28, wx, NUKI_Y + NUKI_H / 2 + 0.03, 0), C.beam);
  }

  const gTop = soffit(0) + 0.03, gBot = NUKI_Y + NUKI_H / 2 - 0.03;
  add(slab(0.20, gTop - gBot, 0.20, 0, (gTop + gBot) / 2, 0, { yp: true, yn: true }), C.beam);

  const shimProfile = [
    [SHIM_HD - 0.03, -SHIM_H], [SHIM_HD, -SHIM_H + 0.06], [SHIM_HD, 0.03],
    [-SHIM_HD, 0.03], [-SHIM_HD, -SHIM_H + 0.06], [-SHIM_HD + 0.03, -SHIM_H],
  ];
  add(sweep(shimProfile, stations, 2), C.beam);

  const capProfile = [
    [CAP_HD, 0], [CAP_HD, CAP_H - 0.06], [CAP_HD - 0.04, CAP_H],
    [-CAP_HD + 0.04, CAP_H], [-CAP_HD, CAP_H - 0.06], [-CAP_HD, 0],
  ];
  add(sweep(capProfile, capStations), C.cap);

  const merged = mergeGeometries(parts.map(({ g, c }) => {
    const geo = g.index ? g.toNonIndexed() : g;
    geo.deleteAttribute('uv');
    geo.deleteAttribute('normal');
    const col = new THREE.Color(c);
    const n = geo.attributes.position.count;
    const arr = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) { arr[i * 3] = col.r; arr[i * 3 + 1] = col.g; arr[i * 3 + 2] = col.b; }
    geo.setAttribute('color', new THREE.BufferAttribute(arr, 3));
    return geo;
  }));
  merged.computeVertexNormals();

  const g = new THREE.Group();
  g.name = 'torii-gate';
  g.add(new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  })));
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;
