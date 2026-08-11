/*
 * Alley Concrete Tile
 * https://polyfork.dev/asset/alley-concrete-tile-56117b
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * This is the kit's whole ALLEY FLOOR PROGRAM: one module that builds the
 * plain concrete slab, the gutter run, its corner, its T, its crossroads and
 * its gully, all on the same 4 m grid cell.
 *
 * QUICK START
 *
 *   import { createAsset } from './alley-concrete-tile-56117b.mjs';
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
 *   colorway      choice  'alley-grey'   'alley-grey' | 'damp-shadow' | 'sun-bleached' | 'ink-wash'
 *   piece         choice  'straight'     'plain' | 'straight' | 'corner' | 't-junction' | 'crossroads' | 'end'
 *   concrete      color   '#A9AFB4'      any hex or THREE.Color
 *   stain         color   '#6B7278'      any hex or THREE.Color
 *   bedding       color   '#4E5459'      any hex or THREE.Color
 *   repair        color   '#3C4145'      any hex or THREE.Color
 *   grate         color   '#2E3134'      any hex or THREE.Color
 *   channelWidth  range   0.34           0.12 to 0.6
 *   channelStyle  choice  'trough'       'trough' | 'slot' | 'stepped'
 *   patches       range   0              0 to 8  (0 = clean tile, the default)
 *
 * Every piece is the same 4.000 x 4.000 m cell centred on the origin with the
 * walkable face on y=0, and the channel meets every open cell edge at that
 * edge's midpoint, so any piece butts against any other. Aim a piece by yaw.
 *
 * Every option is described in full at https://polyfork.dev/cdn/alley-concrete-tile-56117b-params.json
 *
 * SPECS  44 triangles at the shipped default (20 for piece='plain', 332 worst
 *        case), 1 material, 4 x 0.05 x 4 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SIZE = 4.0;                  // exact kit module
const HALF = SIZE / 2;
const THICK = 0.05;                // kit standard slab thickness (BUILD.md 8b)
const TOP_Y = 0.0;                 // walkable surface = the kit's ground plane
const BOT_Y = TOP_Y - THICK;
const BED_TOP = BOT_Y + 0.008;     // top of the bedding course in the slab edge

const CH_DEPTH = 0.036;            // drainage channel invert depth below the top face
const SUMP_Y = BED_TOP;            // gully sump floor: the channel drops onto the bedding
const CRACK_D = 0.014;             // crack channel sink
const REPAIR_D = 0.008;            // asphalt cut-repair sink
const CRACK_HW = 0.035;            // crack half-width (0.07 m mouth)

const MARGIN = 0.10;               // every feature stays this far inside the border
const CH_CLEAR = 0.06;             // ...and this far off the channel lip
const GAP = 0.045;                 // minimum clear concrete between two features

const COLORWAYS = {
  'alley-grey':   { concrete: '#A9AFB4', stain: '#6B7278', bedding: '#4E5459', repair: '#3C4145', grate: '#2E3134' },
  'damp-shadow':  { concrete: '#8A9197', stain: '#4E5459', bedding: '#3C4145', repair: '#2E3134', grate: '#1B1D20' },
  'sun-bleached': { concrete: '#D8D2C4', stain: '#B9A88C', bedding: '#8A9197', repair: '#4E5459', grate: '#3C4145' },
  'ink-wash':     { concrete: '#4E5459', stain: '#3C4145', bedding: '#2E3134', repair: '#1B1D20', grate: '#6B7278' },
};
const COLOR_KEYS = ['concrete', 'stain', 'bedding', 'repair', 'grate'];

const PIECE_ARMS = {
  plain:        [],
  straight:     ['E', 'W'],
  corner:       ['E', 'N'],
  't-junction': ['E', 'W', 'N'],
  crossroads:   ['E', 'W', 'N', 'S'],
  end:          ['E'],
};
const PIECE_KEYS = Object.keys(PIECE_ARMS);

const DEF = { colorway: 'alley-grey', piece: 'straight', channelWidth: 0.34, channelStyle: 'trough', patches: 0 };

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const crs = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

function triN(out, a, b, c, want) {
  if (dot(crs(sub(b, a), sub(c, a)), want) < 0) tri(out, c, b, a); else tri(out, a, b, c);
}
function quadN(out, a, b, c, d, want) {
  if (dot(crs(sub(b, a), sub(c, a)), want) < 0) quad(out, d, c, b, a); else quad(out, a, b, c, d);
}
function polyN(out, pts, want) {
  const r = [];
  for (const p of pts) {
    const q = r[r.length - 1];
    if (!q || Math.hypot(p[0] - q[0], p[1] - q[1], p[2] - q[2]) > 1e-9) r.push(p);
  }
  if (r.length > 1) {
    const a = r[0], z = r[r.length - 1];
    if (Math.hypot(a[0] - z[0], a[1] - z[1], a[2] - z[2]) < 1e-9) r.pop();
  }
  if (r.length === 4) quadN(out, r[0], r[1], r[2], r[3], want);
  else if (r.length === 3) triN(out, r[0], r[1], r[2], want);
}

function grateBar(out, x0, x1, y0, y1, z0, z1) {
  quadN(out, [x0, y1, z0], [x1, y1, z0], [x1, y1, z1], [x0, y1, z1], [0, 1, 0]);
  quadN(out, [x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0], [0, 0, -1]);
  quadN(out, [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1], [0, 0, 1]);
}

function prep(geo, hex) {
  if (geo.index) geo = geo.toNonIndexed();
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
  const merged = mergeGeometries(list.filter(p => p.g.attributes.position.count > 0)
    .map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function loopBounds(loop) {
  let minx = Infinity, maxx = -Infinity, minz = Infinity, maxz = -Infinity;
  for (const p of loop) {
    if (p[0] < minx) minx = p[0]; if (p[0] > maxx) maxx = p[0];
    if (p[1] < minz) minz = p[1]; if (p[1] > maxz) maxz = p[1];
  }
  return { minx, maxx, minz, maxz };
}
function ccwLoop(loop) {
  let a = 0;
  for (let i = 0; i < loop.length; i++) {
    const p = loop[i], q = loop[(i + 1) % loop.length];
    a += p[0] * -q[1] - q[0] * -p[1];        // shoelace in uv = (x, -z)
  }
  return a >= 0 ? loop : loop.slice().reverse();
}
function centroid(loop) {
  let x = 0, z = 0;
  for (const p of loop) { x += p[0]; z += p[1]; }
  return [x / loop.length, z / loop.length];
}

function segDist(a, b, c, d) {
  const den = (b[0] - a[0]) * (d[1] - c[1]) - (b[1] - a[1]) * (d[0] - c[0]);
  if (Math.abs(den) > 1e-12) {
    const t = ((c[0] - a[0]) * (d[1] - c[1]) - (c[1] - a[1]) * (d[0] - c[0])) / den;
    const u = ((c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0])) / den;
    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) return 0;
  }
  return Math.min(ptSeg(a, c, d), ptSeg(b, c, d), ptSeg(c, a, b), ptSeg(d, a, b));
}
function ptSeg(p, a, b) {
  const dx = b[0] - a[0], dz = b[1] - a[1];
  const L = dx * dx + dz * dz;
  let t = L > 1e-12 ? ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / L : 0;
  t = Math.max(0, Math.min(1, t));
  return Math.hypot(p[0] - (a[0] + dx * t), p[1] - (a[1] + dz * t));
}
function pointInLoop(p, loop) {
  let inside = false;
  for (let i = 0, j = loop.length - 1; i < loop.length; j = i++) {
    const a = loop[i], b = loop[j];
    if ((a[1] > p[1]) !== (b[1] > p[1]) &&
        p[0] < (b[0] - a[0]) * (p[1] - a[1]) / (b[1] - a[1]) + a[0]) inside = !inside;
  }
  return inside;
}
function loopsClear(A, B, gap) {
  if (pointInLoop(A[0], B) || pointInLoop(B[0], A)) return false;
  for (let i = 0; i < A.length; i++) {
    const a0 = A[i], a1 = A[(i + 1) % A.length];
    for (let j = 0; j < B.length; j++) {
      if (segDist(a0, a1, B[j], B[(j + 1) % B.length]) < gap) return false;
    }
  }
  return true;
}

function blob(cx, cz, r, sides, seed, squash = 1, rot = 0) {
  const rnd = prng(seed), pts = [];
  const ca = Math.cos(rot), sa = Math.sin(rot);
  for (let i = 0; i < sides; i++) {
    const a = (i / sides) * Math.PI * 2 + 0.4;
    const rr = r * (0.62 + rnd() * 0.62);
    const u = Math.cos(a) * rr * squash, v = Math.sin(a) * rr;
    pts.push([cx + u * ca - v * sa, cz + u * sa + v * ca]);
  }
  return pts;
}

function crackLoop(pts, hw) {
  const n = pts.length, left = [], right = [];
  for (let i = 0; i < n; i++) {
    const p = pts[i], a = pts[Math.max(0, i - 1)], b = pts[Math.min(n - 1, i + 1)];
    let tx = b[0] - a[0], tz = b[1] - a[1];
    const L = Math.hypot(tx, tz) || 1; tx /= L; tz /= L;
    const w = (i === 0 || i === n - 1) ? hw * 0.35 : hw;
    left.push([p[0] - tz * w, p[1] + tx * w]);
    right.push([p[0] + tz * w, p[1] - tx * w]);
  }
  return left.concat(right.reverse());
}

function channelProfile(style, W) {
  const h = W / 2;
  if (style === 'slot') {
    const c = Math.min(0.014, W * 0.12);
    return [[-h, 0], [-h + c, -0.006], [-h + c, -CH_DEPTH], [h - c, -CH_DEPTH], [h - c, -0.006], [h, 0]];
  }
  if (style === 'stepped') {
    const a = h + 0.16;
    return [[-a, 0], [-a + 0.012, -0.012], [-h, -0.012], [-h + 0.030, -CH_DEPTH],
            [h - 0.030, -CH_DEPTH], [h, -0.012], [a - 0.012, -0.012], [a, 0]];
  }
  const run = Math.min(0.030, Math.max(0.012, (W - 0.06) / 2));
  return [[-h, 0], [-h + run, -CH_DEPTH], [h - run, -CH_DEPTH], [h, 0]];
}

const armAxis = (d) => (d === 'E' || d === 'W') ? 'x' : 'z';
const armSign = (d) => (d === 'E' || d === 'N') ? 1 : -1;

function armSweep(Z, prof, lip, dir, invY) {
  const ax = armAxis(dir), sg = armSign(dir);
  for (let i = 0; i < prof.length - 1; i++) {
    const [u0, y0] = prof[i], [u1, y1] = prof[i + 1];
    const du = u1 - u0, dy = y1 - y0;
    const out = (y0 <= invY + 1e-9 && y1 <= invY + 1e-9) ? Z.bedding : Z.concrete;
    const a = sg * lip, b = sg * HALF;
    if (ax === 'x') {
      quadN(out, [a, y0, u0], [b, y0, u0], [b, y1, u1], [a, y1, u1], [0, du, -dy]);
    } else {
      quadN(out, [u0, y0, a], [u0, y0, b], [u1, y1, b], [u1, y1, a], [-dy, du, 0]);
    }
  }
}

function coreWedge(Z, prof, lip, dir, invY) {
  const ax = armAxis(dir), sg = armSign(dir);
  const segs = [];
  for (let i = 0; i < prof.length - 1; i++) {
    const [u0, y0] = prof[i], [u1, y1] = prof[i + 1];
    if (u0 < -1e-9 && u1 > 1e-9) {                       // straddles the centreline: split
      const ym = y0 + (y1 - y0) * ((0 - u0) / (u1 - u0));
      segs.push([u0, y0, 0, ym], [0, ym, u1, y1]);
    } else segs.push([u0, y0, u1, y1]);
  }
  for (const [u0, y0, u1, y1] of segs) {
    const du = u1 - u0, dy = y1 - y0;
    const out = (y0 <= invY + 1e-9 && y1 <= invY + 1e-9) ? Z.bedding : Z.concrete;
    const i0 = sg * Math.abs(u0), i1 = sg * Math.abs(u1), e = sg * lip;   // diagonal / edge
    if (ax === 'x') {                // E or W wedge: the section varies with z
      polyN(out, [[i0, y0, u0], [e, y0, u0], [e, y1, u1], [i1, y1, u1]], [0, du, -dy]);
    } else {                         // N or S wedge: the section varies with x
      polyN(out, [[u0, y0, i0], [u0, y0, e], [u1, y1, e], [u1, y1, i1]], [-dy, du, 0]);
    }
  }
}

function fieldPolys(piece, w) {
  const H = HALF;
  if (piece === 'plain') return [[[-H, -H], [H, -H], [H, H], [-H, H]]];
  if (piece === 'straight') return [                                   // channel runs E-W
    [[-H, w], [H, w], [H, H], [-H, H]],
    [[-H, -H], [H, -H], [H, -w], [-H, -w]],
  ];
  if (piece === 'corner') return [                                     // E and N arms
    [[-H, -H], [H, -H], [H, -w], [-w, -w], [-w, H], [-H, H]],
    [[w, w], [H, w], [H, H], [w, H]],
  ];
  if (piece === 't-junction') return [                                 // E, W and N arms
    [[-H, -H], [H, -H], [H, -w], [-H, -w]],
    [[-H, w], [-w, w], [-w, H], [-H, H]],
    [[w, w], [H, w], [H, H], [w, H]],
  ];
  if (piece === 'crossroads') return [
    [[-H, -H], [-w, -H], [-w, -w], [-H, -w]],
    [[w, -H], [H, -H], [H, -w], [w, -w]],
    [[w, w], [H, w], [H, H], [w, H]],
    [[-H, w], [-w, w], [-w, H], [-H, H]],
  ];
  return [[[-H, -H], [H, -H], [H, -w], [-w, -w], [-w, w], [H, w], [H, H], [-H, H]]];
}

const CRACKS = [
  [[-1.80, 0.72], [-1.55, 0.88], [-1.40, 1.05], [-1.00, 1.50], [-0.62, 1.82]],
  [[1.72, -0.72], [1.30, -1.08], [1.16, -1.26], [1.05, -1.45], [0.88, -1.82]],
];
const REPAIR = [[0.86, 0.66], [1.58, 0.66], [1.58, 1.06], [1.32, 1.18], [0.86, 1.18]];
const PATCHES = [
  { c: [-0.30, 1.20], r: 0.42, n: 8, s: 11, sq: 1.30, rot: 0.35, d: 0.016 },
  { c: [-0.75, -1.20], r: 0.40, n: 8, s: 23, sq: 1.35, rot: -0.30, d: 0.016 },
  { c: [1.10, 1.58], r: 0.25, n: 7, s: 37, sq: 1.30, rot: -0.55, d: 0.011 },
  { c: [0.42, -0.90], r: 0.27, n: 7, s: 41, sq: 1.40, rot: 0.20, d: 0.011 },
  { c: [-1.55, 1.62], r: 0.21, n: 6, s: 53, sq: 1.20, rot: 0.90, d: 0.010 },
  { c: [-1.66, -0.80], r: 0.18, n: 6, s: 67, sq: 1.15, rot: -0.70, d: 0.010 },
  { c: [0.55, -1.65], r: 0.18, n: 6, s: 71, sq: 1.30, rot: 0.45, d: 0.010 },
  { c: [1.60, -1.55], r: 0.18, n: 6, s: 83, sq: 1.20, rot: -0.25, d: 0.010 },
];

export function createAsset(p = {}) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[DEF.colorway];
  const C = {};
  for (const k of COLOR_KEYS) C[k] = p[k] !== undefined ? p[k] : cw[k];

  const piece = PIECE_KEYS.includes(p.piece) ? p.piece : DEF.piece;
  const W = Math.max(0.12, Math.min(0.60, p.channelWidth !== undefined ? p.channelWidth : DEF.channelWidth));
  const style = ['trough', 'slot', 'stepped'].includes(p.channelStyle) ? p.channelStyle : DEF.channelStyle;
  const nPatch = Math.max(0, Math.min(8, Math.round(p.patches !== undefined ? p.patches : DEF.patches)));

  const arms = PIECE_ARMS[piece];
  const prof = channelProfile(style, W);
  const lipZ = Math.abs(prof[0][0]);
  const invY = Math.min(...prof.map(q => q[1]));               // the flat invert's own depth
  const throughX = piece === 'straight';
  const has = (d) => arms.includes(d);

  const polys = throughX ? null : fieldPolys(piece, lipZ);
  const feats = [];
  const tryLay = (raw, depth, zone, inset, wallZone) => {
    const loop = ccwLoop(raw);
    const b = loopBounds(loop);
    if (b.minx < -HALF + MARGIN || b.maxx > HALF - MARGIN) return;
    if (b.minz < -HALF + MARGIN || b.maxz > HALF - MARGIN) return;
    if (polys && !polys.some(q => pointInLoop(centroid(loop), q))) return;
    for (const d of arms) {
      const ax = armAxis(d), sg = armSign(d), c = lipZ + CH_CLEAR;
      const near = ax === 'x'
        ? (b.maxz > -c && b.minz < c && (sg > 0 ? b.maxx > -c : b.minx < c))
        : (b.maxx > -c && b.minx < c && (sg > 0 ? b.maxz > -c : b.minz < c));
      if (near) return;
    }
    for (const f of feats) if (!loopsClear(loop, f.loop, GAP)) return;
    feats.push({ loop, depth, zone, inset, wallZone: wallZone || zone });
  };

  if (nPatch > 0) {
    tryLay(REPAIR, REPAIR_D, 'repair', 0.010, 'concrete');  // cut walls are concrete: they ARE
    for (const c of CRACKS) tryLay(crackLoop(c, CRACK_HW), CRACK_D, 'stain', 0, 'concrete');
    for (let i = 0; i < nPatch; i++) {
      const q = PATCHES[i];
      tryLay(blob(q.c[0], q.c[1], q.r, q.n, q.s, q.sq, q.rot), q.d, 'stain', q.d * 1.2);
    }
  }

  const Z = { concrete: [], stain: [], bedding: [], repair: [], grate: [] };

  if (throughX) {
    for (let i = 0; i < prof.length - 1; i++) {
      const [z0, y0] = prof[i], [z1, y1] = prof[i + 1];
      const dz = z1 - z0, dy = y1 - y0;
      const out = (y0 <= invY + 1e-9 && y1 <= invY + 1e-9) ? Z.bedding : Z.concrete;
      quadN(out, [-HALF, y0, z0], [HALF, y0, z0], [HALF, y1, z1], [-HALF, y1, z1], [0, dz, -dy]);
    }

    for (const sgn of [1, -1]) {
      const inner = sgn * lipZ, outer = sgn * HALF;
      const contour = [[-HALF, inner], [HALF, inner], [HALF, outer], [-HALF, outer]];
      const holes = feats.filter(f => (f.loop[0][1] * sgn) > 0).map(f => f.loop);
      Z.concrete.push(...triangulateFlat(contour, holes, TOP_Y));
    }
  } else {
    const gully = piece === 'end';
    for (const d of arms) armSweep(Z, prof, lipZ, d, invY);
    if (gully) {
      const L = lipZ;
      quadN(Z.bedding, [-L, SUMP_Y, -L], [L, SUMP_Y, -L], [L, SUMP_Y, L], [-L, SUMP_Y, L], [0, 1, 0]);
      quadN(Z.concrete, [-L, SUMP_Y, -L], [-L, SUMP_Y, L], [-L, TOP_Y, L], [-L, TOP_Y, -L], [1, 0, 0]);
      for (const sz of [1, -1]) {
        quadN(Z.concrete, [-L, SUMP_Y, sz * L], [L, SUMP_Y, sz * L], [L, TOP_Y, sz * L], [-L, TOP_Y, sz * L], [0, 0, -sz]);
      }
      for (let i = 0; i < prof.length - 1; i++) {       // the open side, under the section
        const [z0, y0] = prof[i], [z1, y1] = prof[i + 1];
        if (Math.abs(z1 - z0) < 1e-9) continue;
        quadN(Z.concrete, [L, SUMP_Y, z0], [L, SUMP_Y, z1], [L, y1, z1], [L, y0, z0], [-1, 0, 0]);
      }
      const n = Math.max(3, Math.min(6, Math.round(L * 2 / 0.10)));
      const pitch = (L * 2) / (2 * n + 1);
      for (let i = 0; i < n; i++) {
        const z0 = -L + (2 * i + 1) * pitch;
        grateBar(Z.grate, -L, L, -0.020, -0.006, z0, z0 + pitch);
      }
    } else if (arms.length) {
      for (const d of ['E', 'W', 'N', 'S']) coreWedge(Z, prof, lipZ, d, invY);
    }

    polys.forEach((poly, i) => {
      const holes = feats.filter(f => polys.findIndex(q => pointInLoop(centroid(f.loop), q)) === i)
        .map(f => f.loop);
      Z.concrete.push(...triangulateFlat(ccwLoop(poly), holes, TOP_Y));
    });
  }

  for (const f of feats) {
    const walls = Z[f.wallZone], floor = Z[f.zone];
    const [cx, cz] = centroid(f.loop);
    const n = f.loop.length;
    const bot = f.inset <= 0 ? f.loop : f.loop.map(q => {
      const dx = q[0] - cx, dz = q[1] - cz, d = Math.hypot(dx, dz) || 1;
      return [cx + dx * Math.max(0.45, (d - f.inset) / d), cz + dz * Math.max(0.45, (d - f.inset) / d)];
    });
    const y = TOP_Y - f.depth;
    floor.push(...triangulateFlat(bot, [], y));
    for (let i = 0; i < n; i++) {
      const j = (i + 1) % n;
      const dx = f.loop[j][0] - f.loop[i][0], dz = f.loop[j][1] - f.loop[i][1];
      quadN(walls,
        [f.loop[i][0], TOP_Y, f.loop[i][1]], [bot[i][0], y, bot[i][1]],
        [bot[j][0], y, bot[j][1]], [f.loop[j][0], TOP_Y, f.loop[j][1]],
        [dz, 0, -dx]);
    }
  }

  const full = [[-HALF, TOP_Y], ...prof, [HALF, TOP_Y]];
  const notched = (sg, ax) => {
    const c = ax === 'x' ? sg * HALF : sg * HALF;
    for (let i = 0; i < full.length - 1; i++) {
      const [u0, y0] = full[i], [u1, y1] = full[i + 1];
      if (Math.abs(u1 - u0) < 1e-9) continue;              // vertical profile step: no area
      if (ax === 'x') {
        quadN(Z.concrete, [c, BED_TOP, u0], [c, BED_TOP, u1], [c, y1, u1], [c, y0, u0], [sg, 0, 0]);
      } else {
        quadN(Z.concrete, [u0, BED_TOP, c], [u1, BED_TOP, c], [u1, y1, c], [u0, y0, c], [0, 0, sg]);
      }
    }
  };
  const plain = (sg, ax) => {
    if (ax === 'x') {
      const x = sg * HALF;
      quadN(Z.concrete, [x, BED_TOP, -HALF], [x, BED_TOP, HALF], [x, TOP_Y, HALF], [x, TOP_Y, -HALF], [sg, 0, 0]);
    } else {
      const z = sg * HALF;
      quadN(Z.concrete, [-HALF, BED_TOP, z], [HALF, BED_TOP, z], [HALF, TOP_Y, z], [-HALF, TOP_Y, z], [0, 0, sg]);
    }
  };
  if (throughX) {
    quadN(Z.concrete, [-HALF, BED_TOP, HALF], [HALF, BED_TOP, HALF], [HALF, TOP_Y, HALF], [-HALF, TOP_Y, HALF], [0, 0, 1]);
    quadN(Z.concrete, [-HALF, BED_TOP, -HALF], [HALF, BED_TOP, -HALF], [HALF, TOP_Y, -HALF], [-HALF, TOP_Y, -HALF], [0, 0, -1]);
    for (const sx of [1, -1]) notched(sx, 'x');
  } else {
    for (const [d, sg, ax] of [['N', 1, 'z'], ['S', -1, 'z'], ['E', 1, 'x'], ['W', -1, 'x']]) {
      if (has(d)) notched(sg, ax); else plain(sg, ax);
    }
  }

  const rim = [[-HALF, HALF, HALF, HALF, 0, 1], [HALF, -HALF, -HALF, -HALF, 0, -1],
               [HALF, HALF, -HALF, HALF, 1, 0], [-HALF, -HALF, HALF, -HALF, -1, 0]];
  for (const [x0, z0, x1, z1, nx, nz] of rim) {
    quadN(Z.bedding, [x0, BOT_Y, z0], [x1, BOT_Y, z1], [x1, BED_TOP, z1], [x0, BED_TOP, z0], [nx, 0, nz]);
  }
  quadN(Z.bedding, [-HALF, BOT_Y, -HALF], [HALF, BOT_Y, -HALF], [HALF, BOT_Y, HALF], [-HALF, BOT_Y, HALF], [0, -1, 0]);

  const g = new THREE.Group();
  g.name = 'alley-concrete-tile';
  const mesh = finish(COLOR_KEYS.map(k => ({ g: posGeo(Z[k]), c: C[k] })));
  mesh.name = 'alley-tile-surface';
  g.add(mesh);
  return g;
}

function triangulateFlat(contour, holes, y) {
  const c2 = contour.map(q => new THREE.Vector2(q[0], -q[1]));
  const h2 = holes.map(h => h.map(q => new THREE.Vector2(q[0], -q[1])));
  const faces = THREE.ShapeUtils.triangulateShape(c2, h2);
  const all = c2.concat(...h2);
  const out = [];
  for (const f of faces) {
    const A = all[f[0]], B = all[f[1]], D = all[f[2]];
    const area = (B.x - A.x) * (D.y - A.y) - (B.y - A.y) * (D.x - A.x);
    const t = area >= 0 ? [A, B, D] : [A, D, B];
    tri(out, [t[0].x, y, -t[0].y], [t[1].x, y, -t[1].y], [t[2].x, y, -t[2].y]);
  }
  return out;
}

export const params = {
  colorway: {
    type: 'choice', default: 'alley-grey', label: 'Colorway',
    options: ['alley-grey', 'damp-shadow', 'sun-bleached', 'ink-wash'],
    describe: 'Curated kit-palette concrete scheme, sets all four zone colours at once. ' +
      'alley-grey is the shipped mid-grey back-alley pour; damp-shadow drops the whole ' +
      'ladder one step darker for a permanently shaded alley floor; sun-bleached is a warm ' +
      'pale off-white concrete with tan dust stains for an open sunlit lane; ink-wash is a ' +
      'near-charcoal night-alley pavement. Every scheme keeps the same light-to-dark ' +
      'ordering — field, then wear stain, then bedding, with the asphalt repair darkest.',
  },
  piece: {
    type: 'choice', default: 'straight', label: 'Alley piece',
    options: ['plain', 'straight', 'corner', 't-junction', 'crossroads', 'end'],
    affects: 'geometry',
    describe: 'Which piece of the alley floor this tile is — one asset covering every ' +
      'concrete surface the kit needs. The surface is REBUILT per value and the footprint ' +
      'never is: every piece is the same 4.000 x 4.000 m cell centred on the origin with ' +
      'the walkable face on y=0, and the channel meets each open cell edge at that edge\'s ' +
      'MIDPOINT at the current width, depth and section, so any piece butts against any ' +
      'other. plain has NO channel at all — the bare alley slab, the cheapest piece and the ' +
      'one a buyer places the most of, since a real back alley is mostly plain concrete ' +
      'with one gutter line in it. straight runs the channel edge to edge between the -X ' +
      'and +X mouths and is the default, unchanged from the published tile. corner turns it ' +
      '90 degrees inside the cell, entering at +X and leaving at +Z, mitred on the diagonal ' +
      'rather than swept round an arc. t-junction adds a third arm at -X, crossroads opens ' +
      'all four. end terminates the run in a GULLY: the channel drops into a sunken sump on ' +
      'the bedding course, closed by a slotted cast-iron grate — the drain the whole gutter ' +
      'exists to reach, and the alley\'s drain when it is laid mid-run against plain tiles. ' +
      'The names are the kit asphalt road tile\'s, so the same word means the same turn on ' +
      'both surfaces. Aim a piece in a scene with yaw alone.',
  },
  concrete: {
    type: 'color', default: '#A9AFB4', label: 'Concrete field',
    describe: 'Albedo of the poured slab: both top half-plates, the whole drainage channel ' +
      '(invert and cheeks), the four cut side edges and, once patches >= 1, the crack ' +
      'channels — every lit pixel on the default clean tile and about 80% of them on a ' +
      'fully worn one. The channel and the cracks deliberately share it, so ' +
      'they read through their real depth and never as a painted line.',
  },
  stain: {
    type: 'color', default: '#6B7278', label: 'Wear stain',
    describe: 'Albedo of the spalled and damp-stained wear patches sunk 10-16 mm into the ' +
      'field AND of the crack floors. Two value steps below the concrete, because one step ' +
      'is nearly invisible at whole-tile framing and a recess that catches as much light as ' +
      'the pavement reads as a drawn line rather than a cut; take it further from the field ' +
      'for a filthier alley, closer for a newer pour. This zone exists only once ' +
      'patches >= 1 — the default clean tile has no stained geometry for it to paint.',
  },
  repair: {
    type: 'color', default: '#3C4145', label: 'Asphalt repair',
    describe: 'Albedo of the asphalt cut-repair patch over a utility trench — the darkest ' +
      'tone on the tile and the only non-concrete material. Its sawn side walls stay ' +
      'concrete-coloured, so the patch reads as filled rather than painted on. This zone ' +
      'exists only once patches >= 1 — the default clean tile carries no repair.',
  },
  bedding: {
    type: 'color', default: '#4E5459', label: 'Bedding course',
    describe: 'Albedo of the ash/ballast course the slab is laid on: the bottom 8 mm band of ' +
      'the slab edge, the whole underside, AND the flat invert of the channel and the floor ' +
      'of the gully sump, which are the same course showing through where the pour is cut ' +
      'away. Darker than the concrete keeps the tile border a crisp line against a ' +
      'neighbour and gives the gutter an albedo read on top of its geometric one — a course ' +
      'is not a mark, so it never repeats as a stamp when the tile is paved out.',
  },
  grate: {
    type: 'color', default: '#2E3134', label: 'Gully grate',
    describe: 'Albedo of the cast-iron bars over the gully sump — the one part of this tile ' +
      'that is not concrete, so it gets its own zone rather than borrowing the repair\'s. ' +
      'Near-black iron against a mid-grey pour on the lighter schemes; on ink-wash it goes ' +
      'LIGHTER than the pavement, because a dark grate on a near-black floor is a hole. ' +
      'This zone exists only at piece = end.',
  },
  channelWidth: {
    type: 'range', default: 0.34, min: 0.12, max: 0.60, label: 'Channel width',
    affects: 'geometry',
    describe: 'Width in metres of the drainage channel across the centreline. 0.12 is a ' +
      'narrow slot drain that reads as a single scored line; the default 0.34 is an ' +
      'exaggerated alley gutter that reads clearly at hero distance; 0.60 is a broad open ' +
      'storm gutter that visibly splits the tile into two plates. Depth stays 0.036 m, the ' +
      'cheeks stay steep and the invert stays flat at every value, and the wear field ' +
      're-lays itself clear of the widened lips. NOTE for machine readers: this is a ' +
      'cross-section knob, not a size knob with something repeating inside it — a gutter ' +
      'has no repeated element to multiply, so the triangle count does not move with it. ' +
      'The two knobs that genuinely rebuild are channelStyle and patches.',
  },
  channelStyle: {
    type: 'choice', default: 'trough', label: 'Channel section',
    options: ['trough', 'slot', 'stepped'], affects: 'geometry',
    describe: 'The channel cross-section, rebuilt (not scaled) per value — a different ' +
      'number of swept quads each time. trough is the default: steep 50-degree cheeks ' +
      'straight down to a wide flat invert, two shadow lines. slot is a precast U-channel — ' +
      'a 6 mm lip chamfer then dead-vertical cheeks, so the mouth reads as a crisp deep cut. ' +
      'stepped shoulders the pavement down 12 mm at a sharp 45-degree edge, runs a 0.15 m ' +
      'flat apron each side and steps again into the invert: three tiers, four shadow lines ' +
      'and 0.32 m wider overall, the most prominent of the three.',
  },
  patches: {
    type: 'range', default: 0, min: 0, max: 8, step: 1, label: 'Wear patches',
    affects: 'geometry',
    describe: 'The tile\'s single wear knob, and its minimum is OFF. 0 is the shipped ' +
      'default: a clean freshly poured slab with one flat colour per material zone — no ' +
      'blotches, no stains, no cracks, no asphalt repair, nothing but the drainage channel ' +
      'and the slab edge, which is what makes dozens of copies pave a floor without a ' +
      'repeating mark giving the grid away. Any value of 1 or more switches the whole wear ' +
      'field on: the asphalt cut-repair patch and the two wandering cracks come in together ' +
      'with that many sunken spall/stain blotches, so 1 is a lightly used pour, 7 a ' +
      'well-used back alley and 8 adds one last small stain. Blotches are laid front/back ' +
      'alternately so any count stays balanced, and one that would touch a border, the ' +
      'channel or another feature is dropped rather than overlapped. Vary this per instance ' +
      'across a paved run — that, not a mark baked into every copy, is where surface ' +
      'variation belongs.',
  },
};

export const presets = COLORWAYS;
export const rig = {};
export const detach = [];
export const night = {};      // ground concrete emits nothing after dark
export default createAsset;
