/*
 * Wooden Fence Gate
 * https://polyfork.dev/asset/wooden-fence-gate-a8735f
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './wooden-fence-gate-a8735f.mjs';
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
 *   colorway    choice  'oak'          'oak' | 'dark-pine' | 'sun-bleached' | 'weathered-ash' | 'mossy'
 *   post        color   '#75563b'      any hex or THREE.Color
 *   leaf        color   '#8c6a47'      any hex or THREE.Color
 *   brace       color   '#a5855e'      any hex or THREE.Color
 *   grain       color   '#c2a479'      any hex or THREE.Color
 *   gateHeight  range   1.3            1 to 1.45
 *   postGirth   range   1              0.8 to 1.3
 *   bracing     choice  'cross'        'cross' | 'single' | 'twin'
 *
 * Every option is described in full at https://polyfork.dev/cdn/wooden-fence-gate-a8735f-params.json
 *
 * SPECS  408 triangles, 1 material, 2 x 1.3 x 0.32 m (real-world scale).
 * PARTS  animate: gate-leaf
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'oak':           { post: 0x75563b, leaf: 0x8c6a47, brace: 0xa5855e, grain: 0xc2a479 },
  'dark-pine':     { post: 0x4a3527, leaf: 0x5d4430, brace: 0x75563b, grain: 0xa5855e },
  'sun-bleached':  { post: 0xa5855e, leaf: 0xc2a479, brace: 0x8c6a47, grain: 0xe0d2b4 },
  'weathered-ash': { post: 0x57544e, leaf: 0x6e6b63, brace: 0x87847c, grain: 0xa3a099 },
  'mossy':         { post: 0x5d4430, leaf: 0x75563b, brace: 0x2f4f2e, grain: 0xc2a479 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'oak', label: 'Colorway',
    options: ['oak', 'dark-pine', 'sun-bleached', 'weathered-ash', 'mossy'],
    describe: 'curated paint scheme, sets all four timber albedos at once. oak = mid-brown posts under lighter leaf timber and a lighter still brace (the approved default); dark-pine = a much darker, almost bark-brown gate that sinks into shade; sun-bleached = pale silvery-tan driftwood timber, the lightest scheme; weathered-ash = colour drained out to grey lichened timber, the only non-brown scheme; mossy = dark timber whose diagonals have gone deep shaded forest green, so the X reads as the overgrown side of the gate',
  },
  post: {
    type: 'color', default: '#75563b', label: 'Posts',
    describe: 'albedo of both chunky gateposts including their drying-check notches — the darkest and heaviest mass, the anchor value of the asset',
  },
  leaf: {
    type: 'color', default: '#8c6a47', label: 'Leaf timber',
    describe: 'albedo of the swinging gate leaf timber: both vertical stiles and every horizontal rail. Keep it a clear step lighter than the posts or the leaf fuses into them at distance',
  },
  brace: {
    type: 'color', default: '#a5855e', label: 'Diagonal brace',
    describe: 'albedo of the diagonal braces alone. This is the feature that says gate rather than fence, so it wants its own value step off the rails — the X stops reading at thumbnail size when brace and leaf sit within a few points of each other',
  },
  grain: {
    type: 'color', default: '#c2a479', label: 'End grain',
    describe: 'albedo of the sawn end grain on the two post heads: the chamfered shoulder and the flat top face. The sparse pale highlight of the asset and the only value above the leaf timber',
  },
  gateHeight: {
    type: 'range', default: 1.30, min: 1.00, max: 1.45, label: 'Gate height', affects: 'geometry',
    describe: 'height in metres to the post tops, REBUILT not scaled. The post section (0.22 m square), the rail section, the stile section and the 0.225 m bottom rail all stay fixed; only the number of rails changes, filling the leaf at as close to the kit fence pitch of 0.245 m as the height allows. 1.00 = a low three-rail paddock gate (392 triangles), 1.30 = the approved four-rail gate (408), 1.45 = a tall five-rail stock-proof gate (424). Drag it end to end and the triangle count moves in both directions, because rails are really added and removed',
  },
  postGirth: {
    type: 'range', default: 1.0, min: 0.80, max: 1.30, label: 'Post girth', affects: 'geometry',
    describe: 'multiplier on the gateposts\' square section, 0.22 m at 1.0. The posts grow INWARD only — their outer faces stay pinned to the 2.00 m kit fence module at every value — so the leaf is rebuilt narrower as the posts fatten: stiles, rails and the diagonal braces all re-solve to the new clear span. 0.80 = slim 0.18 m sawn posts with a wide airy leaf; 1.30 = squat 0.29 m baulks that eat 0.13 m of the opening and make the gate read as a heavy farmyard entrance',
  },
  bracing: {
    type: 'choice', default: 'cross', label: 'Bracing', affects: 'geometry',
    options: ['cross', 'single', 'twin'],
    describe: 'how the leaf is braced against sagging. cross = one big corner-to-corner X filling the whole leaf, the approved default and the reference gate; single = one diagonal only, rising from the hanging stile at the bottom to the shutting stile at the top, the plain farm-gate Z; twin = a vertical centre stile splitting the leaf into two bays with a smaller X in each, the heaviest and most carpentered of the three. Every value keeps the same rails, stiles and outline — only the diagonal timbers inside the frame change',
  },
};

export const rig = {

  'gate-leaf': { axis: 'y', range: [0, -35] },
};
export const detach = [];

export const night = {};

const ZONE_KEYS = ['post', 'leaf', 'brace', 'grain'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['oak'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {
    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.post) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}

const num = (v, d) => {
  if (v === null || v === undefined || v === '') return d;
  const x = +v; return Number.isFinite(x) ? x : d;
};
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

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
function mergeColored(list) {
  const m = mergeGeometries(list.map(p => prep(p.g, p.c)));
  m.computeVertexNormals();
  return m;
}

function tubeY(pos, sections) {
  for (let s = 0; s < sections.length - 1; s++) {
    const A = sections[s], B = sections[s + 1], n = A.pts.length;
    for (let k = 0; k < n; k++) {
      const k2 = (k + 1) % n;
      quad(pos,
        [A.pts[k][0], A.y, A.pts[k][1]],
        [B.pts[k][0], B.y, B.pts[k][1]],
        [B.pts[k2][0], B.y, B.pts[k2][1]],
        [A.pts[k2][0], A.y, A.pts[k2][1]]);
    }
  }
}

function capY(pos, y, pts, start, top) {
  const n = pts.length;
  const P = (i) => { const p = pts[(start + i) % n]; return [p[0], y, p[1]]; };
  for (let k = 1; k < n - 1; k++) {
    if (top) tri(pos, P(0), P(k + 1), P(k)); else tri(pos, P(0), P(k), P(k + 1));
  }
}

function tubeX(pos, sections, capMin = true, capMax = true) {
  for (let s = 0; s < sections.length - 1; s++) {
    const A = sections[s], B = sections[s + 1], n = A.pts.length;
    for (let k = 0; k < n; k++) {
      const k2 = (k + 1) % n;
      quad(pos,
        [A.x, A.pts[k][0], A.pts[k][1]],
        [A.x, A.pts[k2][0], A.pts[k2][1]],
        [B.x, B.pts[k2][0], B.pts[k2][1]],
        [B.x, B.pts[k][0], B.pts[k][1]]);
    }
  }
  if (capMax) {
    const B = sections[sections.length - 1];
    for (let k = 1; k < B.pts.length - 1; k++)
      tri(pos, [B.x, B.pts[0][0], B.pts[0][1]], [B.x, B.pts[k][0], B.pts[k][1]], [B.x, B.pts[k + 1][0], B.pts[k + 1][1]]);
  }
  if (capMin) {
    const A = sections[0];
    for (let k = 1; k < A.pts.length - 1; k++)
      tri(pos, [A.x, A.pts[0][0], A.pts[0][1]], [A.x, A.pts[k + 1][0], A.pts[k + 1][1]], [A.x, A.pts[k][0], A.pts[k][1]]);
  }
}

function hewnRing(hu, hv, ch, cu = 0, cv = 0) {
  return [
    [cu + hu, cv + hv - ch], [cu + hu - ch, cv + hv],
    [cu - hu + ch, cv + hv], [cu - hu, cv + hv - ch],
    [cu - hu, cv - hv + ch], [cu - hu + ch, cv - hv],
    [cu + hu - ch, cv - hv], [cu + hu, cv - hv + ch],
  ];
}

function postRing(cx, cz, hx, hz, ch, noff, nh, nd) {
  const nx = cx + noff;
  return [
    [cx + hx, cz + hz - ch],
    [cx + hx - ch, cz + hz],
    [nx + nh, cz + hz],
    [nx, cz + hz - nd],
    [nx - nh, cz + hz],
    [cx - hx + ch, cz + hz],
    [cx - hx, cz + hz - ch],
    [cx - hx, cz - hz + ch],
    [cx - hx + ch, cz - hz],
    [cx + hx - ch, cz - hz],
    [cx + hx, cz - hz + ch],
  ];
}

const HALF_W = 1.000;
const POST_HALF = 0.110;
const POST_CZ = -0.025;
const HEAD_H = 0.030;
const HEAD_SC = 0.86;

const RAIL_PITCH = 0.245;
const RAIL_BOT = 0.225;
const RAIL_HH = 0.0475;
const RAIL_Z0 = 0.085, RAIL_Z1 = 0.160;
const RAIL_BURY = 0.035;

const STILE_HW = 0.0475;
const STILE_Z0 = 0.055, STILE_Z1 = 0.185;
const STILE_BOT = 0.094;
const STILE_LAP = 0.020;

const BRACE_HH = 0.046;

const BRACE_BURY = 0.038;

const BRACE_A = [0.070, 0.125];
const BRACE_B = [0.086, 0.141];

function railsFor(H) {
  const stileTop = H - 0.182;
  const topY = stileTop - 0.158;
  const gaps = Math.max(2, Math.round((topY - RAIL_BOT) / RAIL_PITCH));
  const ys = [];
  for (let i = 0; i <= gaps; i++) ys.push(RAIL_BOT + (topY - RAIL_BOT) * (i / gaps));
  return { ys, stileTop };
}

const DEFAULTS = { colorway: 'oak', gateHeight: 1.30, postGirth: 1.0, bracing: 'cross' };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const H = clamp(num(o.gateHeight, 1.30), 1.00, 1.45);
  const G = clamp(num(o.postGirth, 1.0), 0.80, 1.30);
  const bracing = ['cross', 'single', 'twin'].includes(o.bracing) ? o.bracing : 'cross';

  const { ys: RAIL_Y, stileTop: STILE_TOP } = railsFor(H);
  const hx = POST_HALF * G;
  const postCX = HALF_W - hx;
  const postIn = HALF_W - 2 * hx;
  const stileOut = postIn + STILE_LAP;
  const stileCX = stileOut - STILE_HW;
  const stileIn = stileOut - 2 * STILE_HW;
  const railX = stileIn + RAIL_BURY;

  const g = new THREE.Group();
  g.name = 'wooden-fence-gate';

  const mat = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  const statics = [];

  function post(side) {
    const cx = postCX * side;
    const ch = 0.020 * G;
    const noff = -0.015 * G * side;
    const nh = 0.024 * G;
    const ND = 0.042 * G;

    const bodyTop = H - HEAD_H;
    const taper = (y) => 1 - 0.07 * (y / H);
    const ring = (y, nd, sc = 1) => postRing(
      cx, POST_CZ, hx * taper(y) * sc, hx * taper(y) * sc, ch * sc, noff, nh * sc, nd * sc);

    const secs = [
      { y: 0.000, pts: ring(0.000, 0) },
      { y: 0.260, pts: ring(0.260, ND * 0.45) },
      { y: 0.500, pts: ring(0.500, 0) },
      { y: 0.950, pts: ring(0.950, 0) },
      { y: bodyTop, pts: ring(bodyTop, ND) },
    ];
    const pos = [];
    tubeY(pos, secs);
    capY(pos, 0, secs[0].pts, 0, false);
    statics.push({ g: posGeo(pos), c: C.post });

    const headTop = ring(bodyTop, ND, HEAD_SC);
    const head = [];
    tubeY(head, [{ y: bodyTop, pts: secs[4].pts }, { y: H, pts: headTop }]);
    capY(head, H, headTop, 3, true);
    statics.push({ g: posGeo(head), c: C.grain });
  }
  post(1); post(-1);

  const staticMesh = new THREE.Mesh(mergeColored(statics), mat);
  staticMesh.name = 'posts';
  g.add(staticMesh);

  const HINGE_X = -stileOut, HINGE_Z = STILE_Z0;
  const leaf = new THREE.Group();
  leaf.name = 'gate-leaf';
  leaf.position.set(HINGE_X, 0, HINGE_Z);
  const parts = [];

  const sz = (STILE_Z0 + STILE_Z1) / 2, shz = (STILE_Z1 - STILE_Z0) / 2;

  function stile(cx) {
    const pos = [];
    tubeY(pos, [
      { y: STILE_BOT, pts: hewnRing(STILE_HW, shz, 0.016, cx, sz) },
      { y: STILE_TOP, pts: hewnRing(STILE_HW * 0.96, shz * 0.97, 0.016, cx, sz) },
    ]);
    capY(pos, STILE_BOT, hewnRing(STILE_HW, shz, 0.016, cx, sz), 0, false);
    capY(pos, STILE_TOP, hewnRing(STILE_HW * 0.96, shz * 0.97, 0.016, cx, sz), 0, true);
    parts.push({ g: posGeo(pos), c: C.leaf });
  }
  stile(-stileCX); stile(stileCX);
  if (bracing === 'twin') stile(0);

  const rz = (RAIL_Z0 + RAIL_Z1) / 2, rhz = (RAIL_Z1 - RAIL_Z0) / 2;
  for (let i = 0; i < RAIL_Y.length; i++) {
    const y = RAIL_Y[i];
    const odd = i % 2 === 1;
    const a = odd ? 0.94 : 1, b = odd ? 1 : 0.94;
    const pos = [];
    tubeX(pos, [
      { x: -railX, pts: hewnRing(RAIL_HH * a, rhz * a, 0.015, y, rz) },
      { x: railX, pts: hewnRing(RAIL_HH * b, rhz * b, 0.015, y, rz) },
    ], false, false);
    parts.push({ g: posGeo(pos), c: C.leaf });
  }

  function brace(x0, y0, x1, y1, slab) {
    const dx = x1 - x0, dy = y1 - y0;
    const len = Math.hypot(dx, dy), ang = Math.atan2(dy, dx);
    const bz = (slab[0] + slab[1]) / 2, bhz = (slab[1] - slab[0]) / 2;
    const pos = [];
    tubeX(pos, [
      { x: -len / 2, pts: hewnRing(BRACE_HH, bhz, 0.014, 0, 0) },
      { x: len / 2, pts: hewnRing(BRACE_HH * 0.96, bhz, 0.014, 0, 0) },
    ], false, false);
    const geo = posGeo(pos);
    geo.rotateZ(ang);
    geo.translate((x0 + x1) / 2, (y0 + y1) / 2, bz);
    parts.push({ g: geo, c: C.brace });
  }
  const yLo = RAIL_Y[0], yHi = RAIL_Y[RAIL_Y.length - 1];

  const xL = -(stileIn + BRACE_BURY), xR = stileIn + BRACE_BURY;
  if (bracing === 'cross') {
    brace(xL, yLo, xR, yHi, BRACE_A);
    brace(xL, yHi, xR, yLo, BRACE_B);
  } else if (bracing === 'single') {
    brace(xL, yLo, xR, yHi, BRACE_A);
  } else {
    const cL = -(STILE_HW - BRACE_BURY), cR = STILE_HW - BRACE_BURY;
    brace(xL, yLo, cL, yHi, BRACE_A);
    brace(xL, yHi, cL, yLo, BRACE_B);
    brace(cR, yLo, xR, yHi, BRACE_A);
    brace(cR, yHi, xR, yLo, BRACE_B);
  }

  leaf.add(new THREE.Mesh(mergeColored(parts.map(p => ({
    g: p.g.translate(-HINGE_X, 0, -HINGE_Z), c: p.c,
  }))), mat));
  g.add(leaf);

  const bb = new THREE.Box3().setFromObject(g);
  const dx = (bb.min.x + bb.max.x) / 2;
  const dz = (bb.min.z + bb.max.z) / 2;
  const minY = bb.min.y;
  for (const ch of g.children) { ch.position.x -= dx; ch.position.z -= dz; ch.position.y -= minY; }

  return g;
}

export default createAsset;
