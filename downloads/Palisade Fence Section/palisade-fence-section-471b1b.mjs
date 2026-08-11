/*
 * Palisade Fence Section
 * https://polyfork.dev/asset/palisade-fence-section-471b1b
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './palisade-fence-section-471b1b.mjs';
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
 *   colorway     choice  'weathered-oak' 'weathered-oak' | 'sun-bleached' | 'tarred-timber' | 'driftwood-grey'
 *   stakeWood    color   '#9C6B3C'      any hex or THREE.Color
 *   railWood     color   '#6B4526'      any hex or THREE.Color
 *   postWood     color   '#C9975C'      any hex or THREE.Color
 *   lashingRope  color   '#4A2E1B'      any hex or THREE.Color
 *   tallness     range   1              0.78 to 1.22
 *   stakeCount   range   12             9 to 16
 *   endPosts     toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/palisade-fence-section-471b1b-params.json
 *
 * SPECS  464 triangles, 1 material, 2.4 x 1.4 x 0.23 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

/* ---------- params ---------- */

const COLORWAYS = {
  'weathered-oak': { stakeWood: '#9C6B3C', railWood: '#6B4526', postWood: '#C9975C', lashingRope: '#4A2E1B' },
  'sun-bleached':  { stakeWood: '#C4A46A', railWood: '#A88458', postWood: '#DCCBA6', lashingRope: '#6B4526' },
  'tarred-timber': { stakeWood: '#6B4526', railWood: '#4A2E1B', postWood: '#9C6B3C', lashingRope: '#2A2320' },
  'driftwood-grey':{ stakeWood: '#8A8071', railWood: '#5A6462', postWood: '#A79680', lashingRope: '#3E4348' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-oak', label: 'Colorway',
    options: ['weathered-oak', 'sun-bleached', 'tarred-timber', 'driftwood-grey'],
    describe: 'Curated Pirate Cove timber schemes. weathered-oak is mid warm brown stakes with darker rails; sun-bleached is pale sun-dried tan; tarred-timber is dark pitch-soaked brown; driftwood-grey is grey silvered wood. Each sets all four colour zones at once; explicit colour knobs override it.',
  },
  stakeWood: {
    type: 'color', default: '#9C6B3C', label: 'Stake timber',
    describe: 'Albedo of all pointed vertical stakes — the dominant mass of the fence. Keep it a mid-value brown so the darker rails crossing in front and the lighter end posts both separate from it.',
  },
  railWood: {
    type: 'color', default: '#6B4526', label: 'Rail timber',
    describe: 'Albedo of the horizontal rails (two of them at the default height; tallness adds more courses). Should sit a clear value step DARKER than the stakes, because the rails cross in front of them and would otherwise merge into the stake field.',
  },
  postWood: {
    type: 'color', default: '#C9975C', label: 'End post timber',
    describe: 'Albedo of the two square end posts (sawn, not hewn). The lightest zone of the part; it is what marks where one section ends and the next begins in a long run.',
  },
  lashingRope: {
    type: 'color', default: '#4A2E1B', label: 'Lashing rope',
    describe: 'Albedo of the chunky rope collars binding rails to stakes. Near-black tarred hemp — the only non-timber colour; keep it much darker than the rail it wraps.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.78, max: 1.22, affects: 'geometry', label: 'Tallness',
    describe: 'REBUILDS the fence taller, it does not scale it: the horizontal rails are a repeated course at a CONSTANT 0.28 m pitch hung under the stake shoulders, so a taller palisade gains whole wales (with their rope lashings) instead of stretching the two it has. Every section stays put at every value — stake width and 6-sided log section, the 0.217 m sharpened tip, the 0.08 x 0.07 m rail timber, the 0.14 x 0.15 m posts; only stake, post and lashing LENGTHS change. 0.78 is a 1.09 m waist-high stockade edging carrying ONE wale at 0.67 m (384 tris); 1.0 is the standard 1.40 m with TWO wales at 0.69 and 0.97 m (464 tris); 1.22 is a 1.71 m defensive palisade you cannot see over, with THREE wales at 0.72, 1.00 and 1.28 m (544 tris). A wale is added each time the shoulder line clears another 0.28 m above the 0.55 m ground clearance, i.e. at about 1.26 m and 1.54 m overall height. Length stays 2.4 m.',
  },
  stakeCount: {
    type: 'range', default: 12, min: 9, max: 16, step: 1, affects: 'geometry', label: 'Stakes',
    describe: 'How many stakes fill the 2.4 m span; the pitch and stake width adjust to fit. 9 gives fat, widely spaced stakes with daylight between them; 16 gives a tight, near-solid stockade of slimmer stakes. Rope lashings land on every other stake, so their count follows.',
  },
  endPosts: {
    type: 'toggle', default: true, affects: 'geometry', label: 'End posts',
    describe: 'ON: a square flat-topped post closes each end, its outer face flush with the 2.4 m end plane, and the rails die into it. OFF: no posts — the stake row and every rail course run right out to both ends with flat cut faces, so chained copies read as one endless palisade with no post rhythm.',
  },
};

/* ---------- SNIPPETS.md skeleton (via wooden-fence-3d8ee7) ---------- */

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
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  if (!merged) throw new Error('palisade-fence: mergeGeometries returned null');
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

/* Generic lofted prism. rings: equal-length arrays of [x,y,z]; the section ordering
   must be counter-clockwise in its (u,v) plot, where (u,v,sweep) is x,z,+Y for an
   upright sweep and z,y,+X for a sweep along X. `open` drops the closing segment
   (for a shell whose last->first face is buried and would be dead geometry). */
function loft(rings, capA, capB, open = false) {
  const pos = [];
  const N = rings[0].length;
  const last = open ? N - 1 : N;
  for (let r = 0; r < rings.length - 1; r++) {
    const A = rings[r], B = rings[r + 1];
    for (let i = 0; i < last; i++) {
      const j = (i + 1) % N;
      tri(pos, A[i], B[i], B[j]);
      tri(pos, A[i], B[j], A[j]);
    }
  }
  if (capA) { const A = rings[0]; for (let i = 1; i < N - 1; i++) tri(pos, A[0], A[i], A[i + 1]); }
  if (capB) { const B = rings[rings.length - 1]; for (let i = 1; i < N - 1; i++) tri(pos, B[0], B[i + 1], B[i]); }
  return posGeo(pos);
}

// cone/pyramid fan closing the last ring onto a single apex point
function apexFan(ring, apex) {
  const pos = [];
  const N = ring.length;
  for (let i = 0; i < N; i++) tri(pos, ring[i], apex, ring[(i + 1) % N]);
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

/* ---------- geometry constants ---------- */

const HALF_L = 1.2;          // 2.4 m overall; the end planes runs chain on
const BASE_H = 1.4;          // stake tip height at tallness 1
const POST_W = 0.14;         // post cross-section across the fence line
const POST_D = 0.15;         // post depth, matched to the stake logs
const RAIL_HY = 0.040;       // rail half height
const RAIL_ZB = 0.065;       // rail back face (buried 10 mm in the stake flats)
const RAIL_ZF = 0.135;       // rail front face
const RAIL_CH = 0.022;       // chamfer on both front rail edges
const RAIL_PITCH = 0.28;     // CONSTANT vertical pitch of the rail courses (wales)
const RAIL_DROP = 0.304 * BASE_H;  // top wale sits this far below the stake shoulder line
const RAIL_CLEAR = 0.55;     // the lowest wale never comes closer than this to the ground
const TIP_LEN = 0.155 * BASE_H;    // sharpened point: a fixed length of timber, not a ratio
const COLLAR_PROUD = 0.020;  // how far a rope collar stands off the rail all round
const STAKE_ZH = 0.075;      // stake half depth (flats face +/-Z)

// Hand-picked per-stake variation, indexed by j = min(i, N-1-i) so it MIRRORS.
// j=1 carries 1.0 so the tallest stakes exist at every count (size.y stays exact).
const HJ  = [0.965, 1.000, 0.945, 0.990, 0.930, 0.975, 0.955, 0.985];
const WJ  = [1.000, 0.950, 1.080, 0.970, 1.040, 0.920, 1.060, 0.990];
const TJ  = [1.000, 0.920, 1.080, 0.970, 1.050, 0.900, 1.020, 0.950];
const YAW = [0.0, 4.5, -3.0, 5.0, -1.5, 3.5, -4.5, 2.0]; // degrees, sign flips at x=0
const CWJ = [1.000, 1.120, 0.920, 1.060, 0.960, 1.100, 0.900, 1.020]; // collar width

// hexagonal stake section: vertices on +/-X, flat faces toward +/-Z (the rails bed
// on the front flat). CCW in (x,z) as `loft` wants.
function hexSection(xHalf, zHalf) {
  const zs = zHalf / Math.sin(Math.PI / 3);
  const pts = [];
  for (let k = 0; k < 6; k++) {
    const a = k * Math.PI / 3;
    pts.push([xHalf * Math.cos(a), zs * Math.sin(a)]);
  }
  return pts;
}

/* ---------- build ---------- */

export function createAsset(userParams = {}) {
  const P = userParams || {};
  const cw = COLORWAYS[P.colorway] || COLORWAYS[params.colorway.default];
  const C = {
    stake: P.stakeWood   || cw.stakeWood,
    rail:  P.railWood    || cw.railWood,
    post:  P.postWood    || cw.postWood,
    rope:  P.lashingRope || cw.lashingRope,
  };

  const t = THREE.MathUtils.clamp(
    P.tallness === undefined ? params.tallness.default : P.tallness,
    params.tallness.min, params.tallness.max);
  const N = Math.round(THREE.MathUtils.clamp(
    P.stakeCount === undefined ? params.stakeCount.default : P.stakeCount,
    params.stakeCount.min, params.stakeCount.max));
  const withPosts = P.endPosts === undefined ? params.endPosts.default : !!P.endPosts;

  const H = BASE_H * t;
  const postH = 0.83 * H;

  // A SIZE KNOB REBUILDS: the rails are a REPEATED COURSE, not a scaled pair. The top
  // wale hangs a fixed drop under the stake shoulders and the rest step down at the
  // constant 0.28 m pitch until the next one would come inside the 0.55 m ground
  // clearance — so a taller palisade GAINS wales (and their lashings) while every
  // timber section stays exactly the same. r4 keeps the authored 0.9744 / 0.6944 datums
  // exact at the default, so createAsset() still rebuilds refs/approved.glb.
  const r4 = x => Math.round(x * 1e4) / 1e4;
  const topRailY = r4(H - RAIL_DROP);
  const railCourses = 1 + Math.max(0, Math.floor((topRailY - RAIL_CLEAR) / RAIL_PITCH));
  const railY = [];
  for (let r = 0; r < railCourses; r++) railY.push(r4(topRailY - r * RAIL_PITCH));

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  /* --- end posts: square hewn timbers, chamfered flat top, outer face at +/-1.2 --- */
  if (withPosts) {
    for (const s of [-1, 1]) {
      const xo = s * HALF_L;                 // outer face (the chaining plane)
      const xi = s * (HALF_L - POST_W);      // inner face
      const cx = (xo + xi) / 2;
      const ch = 0.035, ci = 0.026;          // top chamfer rise / inset
      const rect = (w, d) => [[w, -d], [w, d], [-w, d], [-w, -d]];
      const ring = (y, inset) => rect(POST_W / 2 - inset, POST_D / 2 - inset)
        .map(([x, z]) => [cx + x, y, z]);
      add(loft([ring(0, 0), ring(postH - ch, 0), ring(postH, ci)], true, true), C.post);
    }
  }

  /* --- stakes: hexagonal hewn logs, tapered, with a sharpened pyramid tip --- */
  const inner = withPosts ? HALF_L - POST_W : HALF_L;
  const pitch = (2 * inner) / N;
  const baseW = Math.min(0.155, 0.80 * pitch);   // narrow daylight gap, per the refs
  const cxs = [];
  for (let i = 0; i < N; i++) {
    const m = N - 1 - i;
    const j = Math.min(i, m);
    const sign = i < m ? 1 : (i > m ? -1 : 0);
    const w = baseW * WJ[j % 8];
    const h = H * HJ[j % 8];
    const tip = TIP_LEN * TJ[j % 8];   // fixed timber length: a point is not scaled
    const cx = -inner + pitch * (i + 0.5);
    cxs.push(cx);

    const sec = hexSection(w / 2, STAKE_ZH * WJ[j % 8]);
    const ring = (y, s) => sec.map(([x, z]) => [x * s, y, z * s]);
    const shoulder = h - tip;
    const g = loft([ring(0, 1), ring(shoulder, 0.90)], true, false);
    const tipG = apexFan(ring(shoulder, 0.90), [0, h, 0]);

    const mat = new THREE.Matrix4()
      .makeTranslation(cx, 0, 0)
      .multiply(new THREE.Matrix4().makeRotationY(THREE.MathUtils.degToRad(sign * YAW[j % 8])));
    g.applyMatrix4(mat); tipG.applyMatrix4(mat);
    add(g, C.stake);
    add(tipG, C.stake);
  }

  /* --- rails: chamfered square timbers laid across the front of the stakes --- */
  // With posts the rail is notched 30 mm INTO the post (deep enough that the joint
  // still reads as joinery in the perspective side view); without them it runs to the
  // end plane with a flat cut face so clones butt.
  const railX = withPosts ? HALF_L - POST_W + 0.03 : HALF_L;
  for (const ry of railY) {
    // section in (z,y), CCW: up the front face, chamfer, back along the top, down the
    // back face, forward along the bottom.
    const sec = [
      [RAIL_ZF, ry - RAIL_HY + RAIL_CH],
      [RAIL_ZF, ry + RAIL_HY - RAIL_CH],
      [RAIL_ZF - RAIL_CH, ry + RAIL_HY],
      [RAIL_ZB, ry + RAIL_HY],
      [RAIL_ZB, ry - RAIL_HY],
      [RAIL_ZF - RAIL_CH, ry - RAIL_HY],
    ];
    const ring = x => sec.map(([z, y]) => [x, y, z]);
    add(loft([ring(-railX), ring(railX)], true, true), C.rail);
  }

  /* --- rope lashings: chunky collars where a rail crosses every other stake --- */
  // j%2 keeps the pattern mirror-symmetric about x=0 at any stake count.
  for (let i = 0; i < N; i++) {
    const j = Math.min(i, N - 1 - i);
    if (j % 2 !== 0) continue;
    const halfW = 0.028 * CWJ[j % 8];
    for (const ry of railY) {
      const zb = RAIL_ZB - 0.010;                 // buried inside the stake
      const zf = RAIL_ZF + COLLAR_PROUD - 0.004;
      const yb = ry - RAIL_HY - COLLAR_PROUD;
      const yt = ry + RAIL_HY + COLLAR_PROUD;
      // (z,y) CCW starting bottom-back, so the CLOSING segment is the back face —
      // dropped with `open` because the stake seals it. The front edge is pinched in
      // 10 mm top and bottom so the collar reads as a bound rope loop, not a staple.
      const sec = [[zb, yb], [zf, yb + 0.010], [zf, yt - 0.010], [zb, yt]];
      const ring = x => sec.map(([z, y]) => [x, y, z]);
      add(loft([ring(cxs[i] - halfW), ring(cxs[i] + halfW)], true, true, true), C.rope);
    }
  }

  const g = new THREE.Group();
  g.name = 'palisade-fence-section';
  const mesh = finish(parts);
  mesh.name = 'palisade';

  // rest on y=0, centered on x/z
  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(
    -(bb.min.x + bb.max.x) / 2,
    -bb.min.y,
    -(bb.min.z + bb.max.z) / 2,
  );

  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};   // dry timber and rope: nothing on a fence emits light
export default createAsset;
