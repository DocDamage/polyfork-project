/*
 * Lamp Post
 * https://polyfork.dev/asset/lamp-post-c9e409
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './lamp-post-c9e409.mjs';
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
 * SPECS  478 triangles, 3 material, 0.26 x 2.2 x 0.58 m (real-world scale).
 * PARTS  animate: lantern
 *        detach: lantern
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

// Wrought-iron street lantern on a chunky wooden post, with glowing candles.
// Medieval Village Kit. Built from scratch (no close catalog match to adapt).
//
// PARAMETRIC. createAsset() with no arguments rebuilds refs/approved.glb exactly:
// every knob's default is the shipped value, and every derived expression collapses
// to the authored literal at that default (heightScale === 1, dY === 0, the section
// table sampled at integer indices).

// ---- colorways (kit menu only for wood / iron / wax / stone; glass and the flame
//      are the brief's two separate non-palette materials) ----
export const COLORWAYS = {
  // the shipped scheme — hand-hewn oak with dark wrought iron
  'oak-iron':      { wood: 0x8c6a4a, woodEnd: 0x6f4e37, iron: 0x3c4550, wax: 0xe8dcc0, stone: 0xb89b72, glass: 0xffe6bf, flame: 0x4a3410, glow: 0xffbe57 },
  // sun-bleached ash post, sawn ends still dark
  'weathered-ash': { wood: 0xb89b72, woodEnd: 0x8c6a4a, iron: 0x3c4550, wax: 0xe8dcc0, stone: 0x6f4e37, glass: 0xf2e8d2, glow: 0xffd38a, flame: 0x4a3410 },
  // painted dark-green ironwork, the village-square lamp
  'village-green': { wood: 0x8c6a4a, woodEnd: 0x6f4e37, iron: 0x4a6a4f, wax: 0xe8dcc0, stone: 0xb89b72, glass: 0xffe6bf, flame: 0x4a3410, glow: 0xffbe57 },
  // oxblood-painted iron on a creosoted post, the market-street lamp
  'market-red':    { wood: 0x6f4e37, woodEnd: 0x8c6a4a, iron: 0x9a3b32, wax: 0xe8dcc0, stone: 0xb89b72, glass: 0xffe6bf, flame: 0x4a3410, glow: 0xffbe57 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: { type: 'choice', default: 'oak-iron', label: 'Colorway',
              options: ['oak-iron', 'weathered-ash', 'village-green', 'market-red'],
              describe: 'curated scheme; sets every zone albedo at once. oak-iron = the shipped warm oak post with near-black wrought iron; weathered-ash = pale sun-bleached timber; village-green = the same post with dark-green painted ironwork; market-red = creosoted dark post with oxblood-painted iron' },

  wood:    { type: 'color', default: '#8c6a4a', label: 'Post timber',
             describe: 'albedo of the whole hand-hewn post shaft (its octagonal faces and bevels are one uniform tone; the darker bevel read comes from scene lighting, not paint)' },
  woodEnd: { type: 'color', default: '#6f4e37', label: 'Sawn ends',
             describe: 'albedo of the post end grain — the sawn cap on top of the timber and its foot; darker than the shaft because it is cut across the grain' },
  iron:    { type: 'color', default: '#3c4550', label: 'Ironwork',
             describe: 'albedo of every wrought-iron part: mount plate, gooseneck bracket and brace, hanging ring, lantern roof, cage posts, collars, bottom finial and the optional post bands' },
  wax:     { type: 'color', default: '#e8dcc0', label: 'Candle wax',
             describe: 'albedo of the candle bodies standing on the lantern floor' },
  stone:   { type: 'color', default: '#b89b72', label: 'Footing stone',
             describe: 'albedo of the optional stone footing collar at the base of the post; only present when the footing knob is on' },
  glass:   { type: 'color', default: '#ffe6bf', label: 'Lantern glass',
             describe: 'albedo of the four translucent lantern panes; pale warm neutral by day, and the zone that leaks candle light after dark (see the night map)' },
  flame:   { type: 'color', default: '#4a3410', label: 'Flame body',
             describe: 'albedo of the small candle flames; dark by day because their emissive glow, not their albedo, is what the eye reads. This is the zone the night map burns' },
  glow:    { type: 'color', default: '#ffbe57', label: 'Flame glow',
             describe: 'emissive colour the candle flames give off — warm gold by default; drives the light the lantern appears to throw, independent of the flame albedo' },

  postHeight: { type: 'range', default: 2.2, min: 1.5, max: 2.4, label: 'Post height', affects: 'geometry',
                describe: 'height of the timber post in metres, measured to its sawn top; 1.5 a low courtyard lamp, 2.2 the shipped street post, 2.4 a tall square lamp. REBUILT, not stretched: the timber gains or loses a whole hewn section at a ~0.5 m pitch, so the height quantizes and the tri count steps with it (3 sections below 1.75 m, 4 up to 2.25 m, 5 above — 462 / 478 / 494 tris). The bracket, lantern and any post bands ride up on the post head at their own fixed size' },
  bands:      { type: 'range', default: 0, min: 0, max: 3, label: 'Iron bands', affects: 'geometry',
                describe: 'whole number of wrought-iron reinforcing collars strapped around the post shaft, spread evenly between the footing and the bracket mount; 0 (default) is the bare shipped timber, 3 is a heavily banded post. They follow the timber taper and stand ~11 mm proud of it' },
  footing:    { type: 'toggle', default: false, label: 'Stone footing', affects: 'geometry',
                describe: 'a tapered stone collar cast around the foot of the post, ~0.25 m tall and ~0.36 m across at the ground; off (default) leaves the bare timber running into the ground as shipped. On, the post foot is closed by the footing instead of its own sawn cap' },
  candles:    { type: 'range', default: 3, min: 1, max: 4, label: 'Candles', affects: 'geometry',
                describe: 'whole number of wax candles burning on the lantern floor (1-4); the tall centre candle is always first, then shorter stubs are added around it, each with its own flame. 1 is a single guttering taper, 4 a full lantern' },
};

export const rig = {
  'lantern': { axis: 'z', range: [0, 16] }, // pendulum swing from the bracket curl
};
export const detach = ['lantern'];

// What lights up after dark. The candle flames burn and the four panes leak that
// light — both are their own colour zones, so a consumer can find them by albedo.
// Nothing else on a timber post emits: the wood, iron, wax and footing stay dark.
export const night = {
  flame: { color: '#ffd98a', intensity: 1.0,
           describe: 'the candle flames themselves, burning pale gold — the source' },
  glass: { color: '#ffb04a', intensity: 0.75,
           describe: 'the four lantern panes glowing warm amber with the candle light behind them' },
};

// ---- raw-tri helpers ----
// WINDING: every call site below hands corners in ring order as seen from OUTSIDE the
// part; three.js wants front faces CCW, which is the reverse. Normalise it here, once,
// instead of at each call site — a per-call-site flip is how parts end up inside-out.
// Flipping tri() also reverses quad() consistently: a-b-c-d -> a-d-c-b.
function tri(out, a, b, c) { out.push(a[0],a[1],a[2], c[0],c[1],c[2], b[0],b[1],b[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

// bake one colored part into vertex-color data
function prep(geo, hex) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i*3]=c.r; col[i*3+1]=c.g; col[i*3+2]=c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}
function mergeColored(list) {
  const m = mergeGeometries(list.map(p => prep(p.g, p.c)));
  m.computeVertexNormals();
  return m;
}
function mergePlain(geos) {
  const m = mergeGeometries(geos.map(x => {
    x = x.toNonIndexed();
    x.deleteAttribute('uv'); x.deleteAttribute('normal'); x.deleteAttribute('color');
    return x;
  }));
  m.computeVertexNormals();
  return m;
}

// ---- param plumbing ----
const ZONE_KEYS = ['wood', 'woodEnd', 'iron', 'wax', 'stone', 'glass', 'flame', 'glow'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['oak-iron'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {
    // explicit knob > colorway preset > post timber
    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.wood) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF; // every zone stays addressable
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const isOn = (v) => !(v === false || v === 'false' || v === 0 || v === '0');

// square-section beam between two points (cross-section in x/z, for near-vertical members)
function beam(pos, p0, p1, r) {
  const c0 = [[p0[0]-r,p0[1],p0[2]-r],[p0[0]+r,p0[1],p0[2]-r],[p0[0]+r,p0[1],p0[2]+r],[p0[0]-r,p0[1],p0[2]+r]];
  const c1 = [[p1[0]-r,p1[1],p1[2]-r],[p1[0]+r,p1[1],p1[2]-r],[p1[0]+r,p1[1],p1[2]+r],[p1[0]-r,p1[1],p1[2]+r]];
  for (let k=0;k<4;k++) quad(pos, c0[k], c0[(k+1)%4], c1[(k+1)%4], c1[k]);
  quad(pos, c0[3],c0[2],c0[1],c0[0]); // cap at p0
  quad(pos, c1[0],c1[1],c1[2],c1[3]); // cap at p1
}

// square rings (x,z), y level
function sqCorners(hw, y, cx=0, cz=0) {
  return [[cx-hw,y,cz-hw],[cx+hw,y,cz-hw],[cx+hw,y,cz+hw],[cx-hw,y,cz+hw]];
}
function sqBand(pos, hw0, y0, hw1, y1) { // y0 lower ring, y1 upper ring
  const a = sqCorners(hw0,y0), b = sqCorners(hw1,y1);
  for (let k=0;k<4;k++) quad(pos, a[k], a[(k+1)%4], b[(k+1)%4], b[k]);
}
function sqFlatRing(pos, hwIn, hwOut, y) { // horizontal annulus (eave underside), faces down
  const a = sqCorners(hwOut,y), b = sqCorners(hwIn,y);
  for (let k=0;k<4;k++) quad(pos, a[k], b[k], b[(k+1)%4], a[(k+1)%4]);
}
function sqCapTop(pos, hw, y) { const a=sqCorners(hw,y); quad(pos, a[0],a[1],a[2],a[3]); }
function sqCapBot(pos, hw, y) { const a=sqCorners(hw,y); quad(pos, a[3],a[2],a[1],a[0]); }
function sqPyramidUp(pos, hw, y0, apexY) { const a=sqCorners(hw,y0), ap=[0,apexY,0];
  for (let k=0;k<4;k++) tri(pos, a[k], a[(k+1)%4], ap); }
function sqPyramidDown(pos, hw, y0, apexY) { const a=sqCorners(hw,y0), ap=[0,apexY,0];
  for (let k=0;k<4;k++) tri(pos, a[(k+1)%4], a[k], ap); }

// octagon (chamfered square) ring of (x,z) points at height y
function octRing(hw, c, cx, cz) {
  const s = hw;
  return [
    [cx+s, cz+(s-c)],[cx+(s-c), cz+s],[cx-(s-c), cz+s],[cx-s, cz+(s-c)],
    [cx-s, cz-(s-c)],[cx-(s-c), cz-s],[cx+(s-c), cz-s],[cx+s, cz-(s-c)],
  ];
}
// octagon walls / caps / annulus, all fed rings of [x,z] pairs (same handedness as octRing)
function octWall(pos, rA, yA, rB, yB) {   // rA lower ring, rB upper ring
  for (let k=0;k<8;k++) quad(pos,
    [rA[k][0],yA,rA[k][1]], [rA[(k+1)%8][0],yA,rA[(k+1)%8][1]],
    [rB[(k+1)%8][0],yB,rB[(k+1)%8][1]], [rB[k][0],yB,rB[k][1]]);
}
function octCapTop(pos, r, y) { for (let k=1;k<7;k++) tri(pos, [r[0][0],y,r[0][1]], [r[k][0],y,r[k][1]], [r[k+1][0],y,r[k+1][1]]); }
function octCapBot(pos, r, y) { for (let k=1;k<7;k++) tri(pos, [r[0][0],y,r[0][1]], [r[k+1][0],y,r[k+1][1]], [r[k][0],y,r[k][1]]); }
function octRingUp(pos, rIn, rOut, y) {   // horizontal annulus facing up
  for (let k=0;k<8;k++) quad(pos,
    [rIn[k][0],y,rIn[k][1]], [rOut[k][0],y,rOut[k][1]],
    [rOut[(k+1)%8][0],y,rOut[(k+1)%8][1]], [rIn[(k+1)%8][0],y,rIn[(k+1)%8][1]]);
}

// flat wrought-iron strap along a (z,y) polyline, thin in x
function strapTube(list, pts, width, thick, color) {
  const n = pts.length;
  const perp = [];
  for (let i=0;i<n;i++) {
    const a = pts[Math.max(0,i-1)], b = pts[Math.min(n-1,i+1)];
    let dz = b[0]-a[0], dy = b[1]-a[1];
    const L = Math.hypot(dz,dy) || 1; dz/=L; dy/=L;
    perp.push([-dy, dz]); // perpendicular in (z,y)
  }
  const ring = (i) => {
    const [z,y] = pts[i], [pz,py] = perp[i];
    const w = width/2, t = thick/2;
    // 4 corners: (x=-t..+t) x (along perp -w..+w)
    return [
      [-t, y - py*w, z - pz*w],
      [-t, y + py*w, z + pz*w],
      [ t, y + py*w, z + pz*w],
      [ t, y - py*w, z - pz*w],
    ];
  };
  const pos = [];
  let A = ring(0);
  quad(pos, A[3],A[2],A[1],A[0]); // start cap
  for (let i=0;i<n-1;i++) {
    const B = ring(i+1);
    for (let k=0;k<4;k++) quad(pos, A[k], A[(k+1)%4], B[(k+1)%4], B[k]);
    A = B;
  }
  quad(pos, A[0],A[1],A[2],A[3]); // end cap
  list.push({ g: posGeo(pos), c: color });
}

function octahedron(pos, cx, cy, cz, rx, ry) {
  const T=[cx,cy+ry,cz], Bt=[cx,cy-ry,cz];
  const m=[[cx+rx,cy,cz],[cx,cy,cz+rx],[cx-rx,cy,cz],[cx,cy,cz-rx]];
  for (let k=0;k<4;k++){ tri(pos,T,m[k],m[(k+1)%4]); tri(pos,Bt,m[(k+1)%4],m[k]); }
}

// ---- the hand-hewn post, as an authored table of section stations -------------
// The post is REBUILT for its height, never stretched: SEC_PITCH holds the hewn
// section at ~0.5 m and the COUNT follows the height. The tables are sampled at a
// FRACTIONAL row index, so at the default (nSec === SEC0) every u is a whole number
// and each station reproduces its authored literal exactly — max vertex delta 0.
const H0 = 2.20, SEC0 = 4, SEC_PITCH = 0.5;   // round(2.20 / 0.5) === 4 === SEC0
const Y_T  = [0.00,  0.60,  1.20,   1.75,   2.20 ];   // station heights at H0
const HW_T = [0.094, 0.090, 0.086,  0.082,  0.074];   // half-width across flats
const CX_T = [0.000, 0.006, -0.005, 0.004,  0.002];   // hand-hewn wonk
const CZ_T = [0.000, 0.005, 0.007,  -0.003, -0.002];
const CH = 0.028;                                     // chamfer that makes it an octagon
const at = (t, u) => {
  const i = Math.floor(u);
  if (i >= t.length - 1) return t[t.length - 1];
  const f = u - i;
  return f === 0 ? t[i] : t[i] + (t[i+1] - t[i]) * f;
};

const DEFAULTS = { colorway: 'oak-iron', postHeight: H0, bands: 0, footing: false, candles: 3 };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const WOOD = C.wood, WOODD = C.woodEnd, IRON = C.iron, WAX = C.wax, STONE = C.stone;

  const H = clamp(num(o.postHeight, H0), 1.5, 2.4);
  const nSec = Math.max(2, Math.round(H / SEC_PITCH));   // one hewn section per ~0.5 m
  const hs = H / H0;                                     // exactly 1 at the default
  const dY = H - H0;                                     // exactly 0 at the default
  const nBands = Math.round(clamp(num(o.bands, 0), 0, 3));
  const footing = isOn(o.footing) && o.footing !== undefined;
  const nCandles = Math.round(clamp(num(o.candles, 3), 1, 4));

  const g = new THREE.Group();
  g.name = 'lamp-post';

  const matMain = new THREE.MeshStandardMaterial({ vertexColors:true, flatShading:true, roughness:0.85, metalness:0 });
  const matGlass = new THREE.MeshStandardMaterial({ color:C.glass, emissive:'#ffcf87',
    emissiveIntensity:0.28, transparent:true, opacity:0.22,
    roughness:0.15, metalness:0, side:THREE.DoubleSide, depthWrite:false });
  const matFlame = new THREE.MeshStandardMaterial({ color:C.flame, emissive:C.glow,
    emissiveIntensity:2.3, roughness:0.6, metalness:0, flatShading:true });

  // ============================================================ STATIC: post + bracket
  const staticParts = [];

  // ---- wooden post (octagon column, darker bevels, subtle hand-hewn wonk) ----
  const lvl = [];
  for (let i = 0; i <= nSec; i++) {
    const u = i * SEC0 / nSec;                            // i exactly, at the default
    lvl.push({ y: at(Y_T, u) * hs, hw: at(HW_T, u), cx: at(CX_T, u), cz: at(CZ_T, u) });
  }
  const rings = lvl.map(l => octRing(l.hw, CH, l.cx, l.cz));
  for (let s=0;s<rings.length-1;s++) {
    const yA = lvl[s].y, yB = lvl[s+1].y, rA = rings[s], rB = rings[s+1];
    for (let k=0;k<8;k++) {
      const a=[rA[k][0], yA, rA[k][1]];
      const b=[rA[(k+1)%8][0], yA, rA[(k+1)%8][1]];
      const c=[rB[(k+1)%8][0], yB, rB[(k+1)%8][1]];
      const d=[rB[k][0], yB, rB[k][1]];
      const pos=[]; quad(pos, a,b,c,d);
      // rule 7b: ONE uniform albedo for the whole timber. The bevel facets read darker
      // from scene lighting for free — painting them darker would double-shade.
      staticParts.push({ g: posGeo(pos), c: WOOD });
    }
  }
  // caps. The foot cap is only built when the timber runs bare into the ground; with
  // the footing on, the stone's own base closes the post instead (two caps on the same
  // plane would z-fight, and the buried one would be dead geometry).
  if (!footing) { const pos=[]; octCapBot(pos, rings[0], lvl[0].y);
    staticParts.push({ g: posGeo(pos), c: WOODD }); }
  { const pos=[]; octCapTop(pos, rings[rings.length-1], lvl[lvl.length-1].y);
    // sawn end grain is a real material difference, not baked shading
    staticParts.push({ g: posGeo(pos), c: WOODD }); }

  // the timber's section at any height, for anything strapped around it
  const postAt = (y) => {
    let s = 0;
    while (s < lvl.length - 2 && y > lvl[s+1].y) s++;
    const f = clamp((y - lvl[s].y) / (lvl[s+1].y - lvl[s].y), 0, 1);
    const L = lvl[s], R = lvl[s+1];
    return { hw: L.hw + (R.hw - L.hw)*f, cx: L.cx + (R.cx - L.cx)*f, cz: L.cz + (R.cz - L.cz)*f };
  };

  // ---- optional stone footing: a tapered collar cast round the foot ----
  const FOOT_Y = 0.25;
  if (footing) {
    const b = postAt(0), t = postAt(FOOT_Y);
    const rBot = octRing(b.hw + 0.085, CH, b.cx, b.cz);
    const rTop = octRing(t.hw + 0.020, CH, t.cx, t.cz);
    const rIn  = octRing(t.hw - 0.004, CH, t.cx, t.cz);   // bedded 4 mm into the timber
    const pos=[];
    octWall(pos, rBot, 0, rTop, FOOT_Y);
    octRingUp(pos, rIn, rTop, FOOT_Y);
    octCapBot(pos, rBot, 0);
    staticParts.push({ g: posGeo(pos), c: STONE });
  }

  // ---- optional wrought-iron reinforcing bands round the shaft ----
  // spread evenly through the clear run of timber, between the footing and the
  // lowest ironwork of the bracket mount, so they never collide with either.
  // On a short post an even spread would bunch them into one stack, so the run holds a
  // minimum pitch and CENTRES itself in the clear span instead (identical spacing to a
  // plain even spread wherever the span is long enough to allow it).
  const BAND_H = 0.06, BAND_LO = FOOT_Y + 0.03, BAND_HI = 1.39 + dY;
  const bandPitch = Math.max((BAND_HI - BAND_LO) / (nBands + 1), 0.16);
  const bandMid = (BAND_LO + BAND_HI) / 2;
  for (let j=0;j<nBands;j++) {
    const y = bandMid + (j - (nBands - 1) / 2) * bandPitch;
    const s0 = postAt(y - BAND_H/2), s1 = postAt(y + BAND_H/2);
    const r0 = octRing(s0.hw + 0.011, CH, s0.cx, s0.cz);
    const r1 = octRing(s1.hw + 0.011, CH, s1.cx, s1.cz);
    const pos=[];
    octWall(pos, r0, y - BAND_H/2, r1, y + BAND_H/2);
    octCapTop(pos, r1, y + BAND_H/2);
    octCapBot(pos, r0, y - BAND_H/2);
    staticParts.push({ g: posGeo(pos), c: IRON });
  }

  // ---- iron mount plate on post front (+z) ----
  staticParts.push({ g: new THREE.BoxGeometry(0.075, 0.5, 0.03).translate(0.006, 1.8 + dY, 0.092), c: IRON });

  // ---- gooseneck bracket strap ----
  strapTube(staticParts, [
    [0.095,1.62+dY],[0.10,1.78+dY],[0.115,1.92+dY],[0.17,2.0+dY],[0.25,2.03+dY],[0.315,2.005+dY],[0.36,1.965+dY],[0.37,1.925+dY],
  ], 0.052, 0.026, IRON);
  // lower diagonal brace strap
  strapTube(staticParts, [
    [0.095,1.66+dY],[0.15,1.83+dY],[0.205,1.99+dY],
  ], 0.045, 0.02, IRON);

  const staticMesh = new THREE.Mesh(mergeColored(staticParts), matMain);
  staticMesh.name = 'post-bracket';
  g.add(staticMesh);

  // ============================================================ LANTERN (hangs / swings / detaches)
  const HP = [0, 1.93 + dY, 0.36]; // hang point (bracket curl)
  const lantern = new THREE.Group();
  lantern.name = 'lantern';
  lantern.position.set(HP[0], HP[1], HP[2]);

  const lanIron = [];   // iron + wax (main material)
  const glassGeo = [];
  const flameGeo = [];

  // ---- hanger: ring + finial rod + top knob ----
  lanIron.push({ g: new THREE.TorusGeometry(0.02, 0.006, 5, 8).rotateY(Math.PI/2).translate(0,-0.028,0), c: IRON });
  { const pos=[]; beam(pos, [0,-0.055,0], [0,-0.008,0], 0.006); lanIron.push({ g: posGeo(pos), c: IRON }); }
  { const pos=[]; octahedron(pos, 0,-0.062,0, 0.02, 0.024); lanIron.push({ g: posGeo(pos), c: IRON }); }

  // ---- roof: pyramid + flared crown + eave underside ----
  { const pos=[];
    sqPyramidUp(pos, 0.10, -0.15, -0.078);          // pitched roof
    sqBand(pos, 0.128, -0.185, 0.10, -0.15);        // flared crown
    sqFlatRing(pos, 0.108, 0.128, -0.185);          // eave underside (closes overhang)
    lanIron.push({ g: posGeo(pos), c: IRON }); }

  // ---- top collar slab (closes cage top; capped both ends so the roof reads solid
  //      from inside the lit cage as well as from outside) ----
  { const pos=[];
    sqBand(pos, 0.11, -0.205, 0.108, -0.185);
    sqCapTop(pos, 0.108, -0.185);
    sqCapBot(pos, 0.11, -0.205);
    lanIron.push({ g: posGeo(pos), c: IRON }); }

  // ---- 4 corner posts of the tapered cage ----
  const TY=-0.205, TW=0.104, BY=-0.465, BW=0.076;
  for (const sx of [-1,1]) for (const sz of [-1,1]) {
    const pos=[]; beam(pos, [sx*BW,BY,sz*BW], [sx*TW,TY,sz*TW], 0.013);
    lanIron.push({ g: posGeo(pos), c: IRON });
  }

  // ---- bottom collar slab (closes cage bottom) ----
  { const pos=[];
    sqBand(pos, 0.079, -0.485, 0.079, -0.463);
    sqCapTop(pos, 0.079, -0.463);
    sqCapBot(pos, 0.079, -0.485);
    lanIron.push({ g: posGeo(pos), c: IRON }); }

  // ---- pointed bottom finial ----
  { const pos=[];
    sqBand(pos, 0.03, -0.52, 0.058, -0.487);
    sqPyramidDown(pos, 0.03, -0.52, -0.565);
    sqCapTop(pos, 0.058, -0.487);
    lanIron.push({ g: posGeo(pos), c: IRON }); }

  // ---- candles (cream wax, on the collar floor). The tall centre taper is always
  //      first, so a 1-candle lantern still reads; stubs are added around it. ----
  const candles = [
    { x:0.0,   z:0.006, r:0.023, h:0.155 },
    { x:-0.036,z:-0.02, r:0.020, h:0.100 },
    { x:0.034, z:0.028, r:0.021, h:0.128 },
    { x:0.010, z:-0.038,r:0.020, h:0.115 },   // 4th: tall enough to read through the glass
  ].slice(0, nCandles);
  for (const c of candles) {
    const floor = -0.463;
    lanIron.push({ g: new THREE.CylinderGeometry(c.r, c.r, c.h, 6).translate(c.x, floor + c.h/2, c.z), c: WAX });
    // flame
    const top = floor + c.h;
    const pos=[]; octahedron(pos, c.x, top+0.026, c.z, 0.013, 0.03); flameGeo.push(posGeo(pos));
  }

  // ---- glass panels (4 sides of the tapered cage, inset just inside the posts) ----
  const gt=0.100, gb=0.072, iy0=-0.205, iy1=-0.465, ot=0.101, ob=0.073;
  const panel = (sign, axis) => {
    let A,B,C2,D;
    if (axis==='z') {
      A=[-gt,iy0,sign*ot]; B=[gt,iy0,sign*ot]; C2=[gb,iy1,sign*ob]; D=[-gb,iy1,sign*ob];
    } else {
      // same ring handedness as the 'z' branch above, so one sign rule covers both axes
      A=[sign*ot,iy0,gt]; B=[sign*ot,iy0,-gt]; C2=[sign*ob,iy1,-gb]; D=[sign*ob,iy1,gb];
    }
    // the -x/-z panels mirror the +x/+z ones, so reverse their ring order to keep every
    // panel's front face pointing out of the cage (never mirror by negating a scale)
    const pos=[];
    if (sign < 0) quad(pos, A,D,C2,B); else quad(pos, A,B,C2,D);
    glassGeo.push(posGeo(pos));
  };
  panel(1,'z'); panel(-1,'z'); panel(1,'x'); panel(-1,'x');

  lantern.add(new THREE.Mesh(mergeColored(lanIron), matMain));
  const glassMesh = new THREE.Mesh(mergePlain(glassGeo), matGlass); glassMesh.name='glass';
  const flameMesh = new THREE.Mesh(mergePlain(flameGeo), matFlame); flameMesh.name='flames';
  lantern.add(glassMesh);
  lantern.add(flameMesh);
  g.add(lantern);

  // ============================================================ center on x/z, rest on y=0
  const box = new THREE.Box3().setFromObject(g);
  const cx = (box.min.x + box.max.x) / 2;
  const cz = (box.min.z + box.max.z) / 2;
  const minY = box.min.y;
  for (const ch of g.children) { ch.position.x -= cx; ch.position.z -= cz; ch.position.y -= minY; }

  return g;
}

export default createAsset;
