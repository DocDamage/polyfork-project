/*
 * Wooden Fence
 * https://polyfork.dev/asset/wooden-fence-3d8ee7
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './wooden-fence-3d8ee7.mjs';
 *   scene.add(createAsset());
 *
 * KNOBS  createAsset() takes an options object; see `export const params` below
 * for the full machine-readable schema (colorway, three colour zones, and the
 * geometry knobs tallness / hewn / wonk / condition). Defaults reproduce the
 * asset exactly:
 *
 *   scene.add(createAsset({ colorway: 'limewashed', tallness: 1.3, condition: 'broken' }));
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
 * SPECS  464 triangles at the defaults (604 at tallness 1.3), 1 material, 2 x 1.22 x 0.15 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

/* ---------------------------------------------------------------- colorways --
   Zones: post shafts, rails (incl. the tenon ends), axe-cut end-grain caps.
   One material — weathered timber — so the colorways are TIMBER TYPES, all drawn
   from the kit menu (#8c6a4a #b89b72 #e8dcc0 #6f4e37 #3c4550). */
export const COLORWAYS = {
  'weathered-oak': { post: 0x8c6a4a, rail: 0xb89b72, grain: 0x6f4e37 },
  'aged-oak':      { post: 0x6f4e37, rail: 0x8c6a4a, grain: 0x3c4550 },
  'sun-bleached':  { post: 0xb89b72, rail: 0xe8dcc0, grain: 0x8c6a4a },
  'limewashed':    { post: 0x6f4e37, rail: 0xe8dcc0, grain: 0x8c6a4a },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-oak', label: 'Colorway',
    options: ['weathered-oak', 'aged-oak', 'sun-bleached', 'limewashed'],
    describe: 'curated timber scheme; sets all three zone albedos at once. weathered-oak = mid-brown posts under lighter sun-bleached rails (the shipped look); aged-oak = dark old timber with near-black cut ends; sun-bleached = pale tan posts under cream rails, a fence left out in the sun; limewashed = dark posts under cream-painted rails, the highest-contrast pair',
  },
  post: {
    type: 'color', default: '#8c6a4a', label: 'Post timber',
    describe: 'albedo of both post shafts (the two dark vertical masses, ~30% of the model). Does not touch the rails or the cut tops',
  },
  rail: {
    type: 'color', default: '#b89b72', label: 'Rail timber',
    describe: 'albedo of every horizontal split rail INCLUDING the tenon ends that poke past the posts — they are the same member, so they always carry this tone. The dominant mass, ~60%',
  },
  grain: {
    type: 'color', default: '#6f4e37', label: 'End grain',
    describe: 'albedo of the slanted axe-cut wedge cap on each post top (~10%). Keep it darker than the post timber or the fresh-cut read is lost',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.8, max: 1.3, label: 'Tallness', affects: 'geometry',
    describe: 'height of the fence, REBUILT not scaled: the post shaft gets longer while its 0.15 m section and its axe-cut cap stay exactly the same size, and the rails re-hang at a CONSTANT 0.42 m pitch from 0.25 m below the post top — so the segment gains a THIRD rail above 1.23 (tri count rises 464 -> 604). 0.8 = a low 1.00 m paddock rail, 1.0 = the shipped 1.22 m fence, 1.3 = a 1.54 m three-rail stock fence. Length always stays the 2 m kit module',
  },
  hewn: {
    type: 'range', default: 1.0, min: 0, max: 2, label: 'Hewn irregularity', affects: 'geometry',
    describe: 'how much each rail swells and pinches along its length (and wanders vertically). 0 = a dead-uniform sawn prism, planed lumber; 1 = the shipped +/-25% axe-split timber; 2 = +/-50%, a violently hand-split rail with fat swellings and thin waists. Triangle-neutral: it moves the section at each station, never the station count',
  },
  wonk: {
    type: 'range', default: 1.0, min: 0, max: 2, label: 'Wonk', affects: 'geometry',
    describe: 'how hand-set the posts look — a multiplier on post lean, yaw and tilt. 0 = both posts dead plumb and square, a tidy new fence; 1 = the shipped 3.5 deg / 1.6 deg lean, both the same way; 2 = strongly wonky AND SPLAYED, the two posts leaning OPPOSITE ways (5 deg one way, -3.6 deg the other, yawed 10 deg and 8 deg) so the segment reads hand-set rather than tipping over. The rails stay dead level at every value',
  },
  condition: {
    type: 'choice', default: 'sound', label: 'Condition', affects: 'geometry',
    options: ['sound', 'broken'],
    describe: 'state of the segment. sound = both rails run the full 2 m module; broken = the top rail has snapped off just past the middle, leaving a short splintered stub, and the now-unsupported right-hand post leans a further 4.5 deg. The bottom rail, the footprint and both tenon ends on the left are untouched, so a broken piece still chains onto a sound one',
  },
};

export const rig = {};        // nothing on a fence swings, spins or slides
export const detach = [];     // nothing is removable — rails are through-tenoned

// A fence emits nothing after dark: no panes, no lamp, no lens, no fire (BUILD.md
// craft rule 7c names a fence explicitly as a thing that stays dark).
export const night = {};

/* ---------- colour resolution: schema defaults -> colorway -> explicit knob ---- */
const ZONE_KEYS = ['post', 'rail', 'grain'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['weathered-oak'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {
    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.rail) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;  // keep every zone addressable
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

/* ---------- SNIPPETS.md skeleton ---------- */
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

function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

/* ---------- generic lofted prism ----------
   rings: array of equal-length arrays of [x,y,z].
   Side quads are wound so the ring order chosen below faces outward; the first ring's
   fan cap faces "backwards" along the sweep, the last ring's forwards. */
function loft(rings, capA, capB) {
  const pos = [];
  const N = rings[0].length;
  for (let r = 0; r < rings.length - 1; r++) {
    const A = rings[r], B = rings[r + 1];
    for (let i = 0; i < N; i++) {
      const j = (i + 1) % N;
      tri(pos, A[i], B[i], B[j]);
      tri(pos, A[i], B[j], A[j]);
    }
  }
  if (capA) { const A = rings[0]; for (let i = 1; i < N - 1; i++) tri(pos, A[0], A[i], A[i + 1]); }
  if (capB) { const B = rings[rings.length - 1]; for (let i = 1; i < N - 1; i++) tri(pos, B[0], B[i + 1], B[i]); }
  return posGeo(pos);
}

// 8-point chamfered rectangle in a (u,v) plane, ordered so `loft` faces outward.
function chamferSection(hu, hv, c) {
  const k = Math.min(c, hu * 0.6, hv * 0.6);
  return [
    [hu, -hv + k], [hu, hv - k], [hu - k, hv], [-hu + k, hv],
    [-hu, hv - k], [-hu, -hv + k], [-hu + k, -hv], [hu - k, -hv],
  ];
}

/* ---------- rails: hand-hewn split timber swept along X ----------
   Stations are hand-authored (never a formula): irregular runs of two long swellings
   then a short pinch, per LESSONS "vary amplitude AND wavelength". Each rail owns its
   OWN phase and run lengths — parallel members that swell in the same places read as
   one stamped repeat. */
function railRings(yBase, stations, chamfer) {
  return stations.map(s => {
    // section lives in (z,v=y): at the +z extreme the tangent runs +y  ->  outward normals
    const sec = chamferSection(s.d, s.h, chamfer);
    return sec.map(([z, y]) => [s.x, yBase + s.dy + y, (s.dz || 0) + z]);
  });
}

function buildRail(yBase, stations, C) {
  // one continuous member: the protruding tenon ends are the SAME timber as the rail,
  // so they read light against the darker posts instead of mushing into them
  add(loft(railRings(yBase, stations, 0.012), true, true), C.rail);
}

// x, dy/dz (the split log's wander), h (half height), d (half depth)
const TOP_RAIL = [
  { x: -1.000, dy: 0.000, dz: 0.000, h: 0.052, d: 0.038 },
  { x: -0.895, dy: 0.004, dz: 0.004, h: 0.058, d: 0.042 },
  { x: -0.620, dy: 0.011, dz: 0.009, h: 0.071, d: 0.049 },
  { x: -0.300, dy: 0.004, dz: 0.003, h: 0.061, d: 0.043 },
  { x: -0.020, dy: -0.007, dz: -0.006, h: 0.074, d: 0.050 },
  { x: 0.255, dy: -0.002, dz: -0.002, h: 0.058, d: 0.042 },
  { x: 0.555, dy: 0.007, dz: 0.007, h: 0.072, d: 0.049 },
  { x: 0.865, dy: 0.002, dz: 0.002, h: 0.059, d: 0.043 },
  { x: 1.000, dy: 0.000, dz: 0.000, h: 0.050, d: 0.037 },
];
const BOTTOM_RAIL = [
  { x: -1.000, dy: 0.000, dz: 0.000, h: 0.051, d: 0.038 },
  { x: -0.895, dy: -0.005, dz: -0.005, h: 0.062, d: 0.044 },
  { x: -0.545, dy: -0.011, dz: -0.009, h: 0.074, d: 0.050 },
  { x: -0.240, dy: -0.002, dz: 0.004, h: 0.057, d: 0.041 },
  { x: 0.055, dy: 0.006, dz: 0.008, h: 0.070, d: 0.048 },
  { x: 0.300, dy: 0.010, dz: 0.003, h: 0.064, d: 0.045 },
  { x: 0.620, dy: 0.002, dz: -0.007, h: 0.075, d: 0.051 },
  { x: 0.880, dy: -0.004, dz: -0.003, h: 0.058, d: 0.042 },
  { x: 1.000, dy: 0.000, dz: 0.000, h: 0.051, d: 0.038 },
];
// third rail — only built at tallness >= ~1.28. Its own phase again: the pinch lands
// where the other two swell.
const MID_RAIL = [
  { x: -1.000, dy: 0.000, dz: 0.000, h: 0.050, d: 0.037 },
  { x: -0.780, dy: 0.008, dz: 0.006, h: 0.073, d: 0.050 },
  { x: -0.415, dy: 0.003, dz: -0.004, h: 0.056, d: 0.041 },
  { x: -0.130, dy: -0.009, dz: -0.007, h: 0.072, d: 0.049 },
  { x: 0.170, dy: -0.003, dz: 0.005, h: 0.059, d: 0.043 },
  { x: 0.480, dy: 0.009, dz: 0.008, h: 0.075, d: 0.051 },
  { x: 0.735, dy: 0.001, dz: 0.002, h: 0.057, d: 0.042 },
  { x: 0.905, dy: -0.005, dz: -0.004, h: 0.068, d: 0.047 },
  { x: 1.000, dy: 0.000, dz: 0.000, h: 0.052, d: 0.038 },
];
const RAIL_TABLES = [TOP_RAIL, BOTTOM_RAIL, MID_RAIL];

// `hewn`: push every station's section away from (or toward) the member's MEAN
// section, and scale the vertical/depth wander with it. k === 1 returns the authored
// table untouched, so the default build is bit-identical.
function hewnStations(list, k) {
  if (k === 1) return list;
  const mh = list.reduce((s, p) => s + p.h, 0) / list.length;
  const md = list.reduce((s, p) => s + p.d, 0) / list.length;
  return list.map(s => ({
    x: s.x, dy: s.dy * k, dz: s.dz * k,
    h: mh + (s.h - mh) * k, d: md + (s.d - md) * k,
  }));
}

// `condition: 'broken'`: snap the top rail off just past the middle and finish it with
// two pinched stations, so the break reads as splintered timber rather than a sawn end.
function snapRail(list) {
  const kept = list.filter(s => s.x < 0.28);
  const last = kept[kept.length - 1];
  return [
    ...kept,
    { x: 0.330, dy: last.dy - 0.006, dz: last.dz, h: last.h * 0.72, d: last.d * 0.80 },
    { x: 0.408, dy: last.dy - 0.017, dz: last.dz, h: last.h * 0.30, d: last.d * 0.42 },
  ];
}

/* ---------- posts: chunky hewn slabs, swept up Y, leaned and yawed ---------- */
// y, w (half width across the fence line), d (half depth), slant (top-cut tilt factor)
const POST_STATIONS = [
  { y: -0.045, w: 0.077, d: 0.067, slant: 0 },
  { y: 0.300, w: 0.075, d: 0.065, slant: 0 },
  { y: 0.720, w: 0.071, d: 0.062, slant: 0 },
  { y: 1.030, w: 0.067, d: 0.058, slant: 0 },
  { y: 1.105, w: 0.064, d: 0.055, slant: 0.12 },
  { y: 1.150, w: 0.051, d: 0.044, slant: 0.34 },
];
const POST_BASE = -0.045;      // buried end
const POST_BODY_TOP = 1.030;   // last body ring; everything above is the axe-cut cap

// `tallness` REBUILDS the post: the shaft between the base and the last body ring
// stretches, every section width stays exactly as authored (a 0.15 m baulk is a
// 0.15 m baulk on a short fence and a tall one), and the cap rides up rigid so the
// axe cut keeps its real size.
function postY(y, t) {
  if (t === 1) return y;
  if (y <= POST_BODY_TOP) return POST_BASE + (y - POST_BASE) * t;
  return y + (POST_BODY_TOP - POST_BASE) * (t - 1);
}

function buildPost(px, leanDeg, yawDeg, tiltDeg, widthScale, t, C) {
  const rings = POST_STATIONS.map(s => {
    // section in (u=x, v=z): at the +x extreme the tangent runs +z -> outward normals
    const sec = chamferSection(s.w * widthScale, s.d, 0.015);
    // axe-cut top: the cap plane tilts across the post so it reads as a hewn cut
    const y = postY(s.y, t);
    return sec.map(([x, z]) => [x, y + s.slant * x, z]);
  });
  const m = new THREE.Matrix4()
    .makeTranslation(px, 0, 0)
    .multiply(new THREE.Matrix4().makeRotationY(THREE.MathUtils.degToRad(yawDeg)))
    .multiply(new THREE.Matrix4().makeRotationZ(THREE.MathUtils.degToRad(leanDeg)))
    .multiply(new THREE.Matrix4().makeRotationX(THREE.MathUtils.degToRad(tiltDeg)));

  const split = 4; // rings 0..4 = post body, rings 4..5 = the dark end-grain cap
  const body = loft(rings.slice(0, split + 1), true, false);
  const cap = loft(rings.slice(split), false, true);
  body.applyMatrix4(m); cap.applyMatrix4(m);
  add(body, C.post);
  add(cap, C.grain);
}

// Post pose vs `wonk`. At w === 1 these are the shipped angles exactly (x * 1 is exact).
// Past 1 the right-hand post crosses through plumb and leans the OTHER way, so the pair
// SPLAYS instead of both tipping the same direction (LESSON.md: "wonky wants opposing
// signs, not just non-zero angles").
function postPose(w) {
  return [
    { px: -0.820, lean: w <= 1 ? 3.5 * w : 3.5 + 1.5 * (w - 1), yaw: -5.0 * w, tilt: 1.2 * w, widthScale: 1.00 },
    { px: 0.820, lean: w <= 1 ? 1.6 * w : 1.6 - 5.2 * (w - 1), yaw: 4.0 * w, tilt: -0.9 * w, widthScale: 0.96 },
  ];
}

// Rail heights vs `tallness`: the top rail hangs 0.25 m below the post top and the rest
// follow at a constant 0.42 m pitch while they clear 0.30 m off the buried base — so
// height buys RAILS, it does not stretch the spacing.
const RAIL_PITCH = 0.42;
function railBases(t) {
  if (t === 1) return [0.900, 0.480];             // the shipped pair, exactly
  const top = 0.900 + (POST_BODY_TOP - POST_BASE) * (t - 1);
  const out = [top];
  while (out.length < 4 && out[out.length - 1] - RAIL_PITCH >= 0.30) out.push(out[out.length - 1] - RAIL_PITCH);
  while (out.length < 2) out.push(out[out.length - 1] - RAIL_PITCH);  // never fewer than the briefed two
  return out;
}

const DEFAULTS = { colorway: 'weathered-oak', tallness: 1, hewn: 1, wonk: 1, condition: 'sound' };

export function createAsset(opts = {}) {
  parts.length = 0;
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const t = clamp(num(o.tallness, 1), 0.8, 1.4);
  const k = clamp(num(o.hewn, 1), 0, 2);
  const w = clamp(num(o.wonk, 1), 0, 2);
  const broken = String(o.condition) === 'broken';

  const g = new THREE.Group();
  g.name = 'wooden-fence';

  // posts first so the rails read as laid across them
  for (const p of postPose(w)) {
    // a snapped top rail leaves the right-hand post carrying nothing: it lists further
    const lean = broken && p.px > 0 ? p.lean + 4.5 : p.lean;
    buildPost(p.px, lean, p.yaw, p.tilt, p.widthScale, t, C);
  }

  const bases = railBases(t);
  for (let i = 0; i < bases.length; i++) {
    let stations = hewnStations(RAIL_TABLES[i % RAIL_TABLES.length], k);
    if (broken && i === 0) stations = snapRail(stations);
    buildRail(bases[i], stations, C);
  }

  const mesh = finish(parts);
  mesh.name = 'fence-body';

  // rest on y=0, centered on x/z
  // The module datum in X is the RAIL SPAN (x = -1.000 .. +1.000), which is where the
  // tenons cross the cell edge and chain onto the next segment — it is already centred,
  // so there is no X shift. Re-centring on the BBOX instead would slide those joints off
  // the 2 m grid at any knob value where a leaning post top crosses the module line.
  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(0, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  g.add(mesh);
  return g;
}

export default createAsset;
