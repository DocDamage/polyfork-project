/*
 * Dock Lantern Post
 * https://polyfork.dev/asset/dock-lantern-post-5e58a4
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './dock-lantern-post-5e58a4.mjs';
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
 *   colorway     choice  'harbour-oak'  'harbour-oak' | 'salt-bleached' | 'tarred-pitch' | 'harbour-green'
 *   post         color   '#9C6B3C'      any hex or THREE.Color
 *   postCap      color   '#B99B68'      any hex or THREE.Color
 *   iron         color   '#3E4348'      any hex or THREE.Color
 *   roof         color   '#5A6462'      any hex or THREE.Color
 *   pane         color   '#E0B33C'      any hex or THREE.Color
 *   tallness     range   1              0.68 to 1.07
 *   flare        range   1              0.45 to 1.9
 *   armReach     range   0.652          0.56 to 0.92
 *   lanternSize  range   1              0.8 to 1.15
 *
 * Every option is described in full at https://polyfork.dev/cdn/dock-lantern-post-5e58a4-params.json
 *
 * SPECS  246 triangles, 1 material, 0.51 x 2.6 x 0.94 m (real-world scale).
 * PARTS  animate: lantern
 *        detach: lantern
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'harbour-oak':   { post: '#9C6B3C', postCap: '#B99B68', iron: '#3E4348', roof: '#5A6462', pane: '#E0B33C' },
  'salt-bleached': { post: '#A79680', postCap: '#DCCBA6', iron: '#6E757A', roof: '#7C8683', pane: '#E0A579' },
  'tarred-pitch':  { post: '#4A2E1B', postCap: '#8A8071', iron: '#2A2320', roof: '#3E4348', pane: '#C9975C' },
  'harbour-green': { post: '#6B4526', postCap: '#A88458', iron: '#5A6462', roof: '#9AA3A0', pane: '#58C8C0' },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'harbour-oak', label: 'Colorway', affects: 'colors',
    options: ['harbour-oak', 'salt-bleached', 'tarred-pitch', 'harbour-green'],
    describe: 'Curated Pirate Cove scheme. harbour-oak is the default warm oak post with dark slate iron and amber glass; salt-bleached is a sun-greyed driftwood post with pewter iron and pale peach glass; tarred-pitch is a near-black tarred post and ironwork with a dull tan pane; harbour-green is a dark timber post with grey-green iron and a cold sea-green lens.',
  },
  post: {
    type: 'color', default: '#9C6B3C', label: 'Post timber', affects: 'colors',
    describe: 'Albedo of the entire timber post — every one of its eight facets, the splayed foot and the underside. This is the dominant mass; the facet tone differences come from scene lighting, so a second wood tone here would double-shade it.',
  },
  postCap: {
    type: 'color', default: '#B99B68', label: 'Post end grain', affects: 'colors',
    describe: 'Albedo of the small sawn octagon capping the post head. A real material change (cut end grain), so keep it a clear step LIGHTER than the shaft or the chamfered cap stops reading as a cut.',
  },
  iron: {
    type: 'color', default: '#3E4348', label: 'Ironwork', affects: 'colors',
    describe: 'Albedo of every wrought-iron member: the bracket arm, the knee brace, the mount strap and its bolt peg, and the lantern corner bars, collars and plinth. Dark desaturated slate reads as tarred iron; lighter than the post timber inverts the value ladder and the bracket dissolves into the post.',
  },
  roof: {
    type: 'color', default: '#5A6462', label: 'Lantern roof', affects: 'colors',
    describe: 'Albedo of the flared pyramidal roof cap and its downturned skirt. One step lighter than the ironwork so the roof separates from the corner bars beneath it; too light and it reads as a painted lid rather than sheet iron.',
  },
  pane: {
    type: 'color', default: '#E0B33C', label: 'Amber glass', affects: 'colors',
    describe: 'Albedo of the four recessed glass faces. This is the lightest zone and the only warm accent on the asset, and it is also the surface `night` lights up, so it must stay its own colour and never match the ironwork.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.68, max: 1.07, affects: 'geometry', label: 'Post height',
    describe: 'Scales the post height about the ground. At 0.68 the post is 1.77 m — a squat bollard lamp whose head hangs at chest height and nearly fills the post; at 1.0 it is the 2.60 m reference; at 1.07 it is a 2.78 m quayside post. The range runs short rather than tall on purpose: the lamp head, bracket and brace keep their own size and ride at fixed offsets below the post head, so shortening the post is what visibly changes the object. The splayed foot keeps its proportions at every value.',
  },
  flare: {
    type: 'range', default: 1.0, min: 0.45, max: 1.90, affects: 'geometry', label: 'Foot splay',
    describe: 'How far the post swells below the kink at one third height. At 0.45 the post is an almost parallel-sided stake 0.22 m across at the ground; at 1.0 it is the reference 0.33 m concave dock foot; at 1.90 it is a heavily splayed 0.46 m pile that visibly plants itself. Only the shape below the kink changes; the shaft, bracket and lantern do not move.',
  },
  armReach: {
    type: 'range', default: 0.652, min: 0.56, max: 0.92, affects: 'geometry', label: 'Arm reach',
    describe: 'Distance in metres from the post axis to the tip of the bracket arm, measured along +Z. At 0.56 the lantern tucks in close over the post; at 0.652 it is the reference overhang; at 0.92 it swings a long way out over the water. The knee brace, the hang point and the lantern all follow the arm, and the beam always overshoots the lantern.',
  },
  lanternSize: {
    type: 'range', default: 1.0, min: 0.80, max: 1.15, affects: 'geometry', label: 'Lantern size',
    describe: 'Uniform scale of the whole lamp head about its hang point. At 0.80 it is a compact 0.41 m wide lamp on a comparatively heavy bracket; at 1.0 it is the reference 0.51 m head; at 1.15 it is an oversized harbour lantern that dominates the post. The hanger stays welded to the arm at every value, and the arm lengthens just enough to keep an oversized head clear of the post.',
  },
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const BASIS = {
  y: [[1, 0, 0], [0, 0, 1]],
  z: [[1, 0, 0], [0, -1, 0]],
  x: [[0, 0, -1], [0, -1, 0]],
};
function ringAxis(axis, n, ru, rv, c, phase = 0) {
  const [e1, e2] = BASIS[axis], out = [];
  for (let k = 0; k < n; k++) {
    const a = phase + (k * 2 * Math.PI) / n, cu = Math.cos(a) * ru, cv = Math.sin(a) * rv;
    out.push([c[0] + e1[0] * cu + e2[0] * cv, c[1] + e1[1] * cu + e2[1] * cv, c[2] + e1[2] * cu + e2[2] * cv]);
  }
  return out;
}

function ringDir(d, n, ru, rv, c, phase = 0) {
  const D = new THREE.Vector3(...d).normalize();
  const tmp = Math.abs(D.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
  const e1 = new THREE.Vector3().crossVectors(D, tmp).normalize();
  const e2 = new THREE.Vector3().crossVectors(D, e1).negate();
  const out = [];
  for (let k = 0; k < n; k++) {
    const a = phase + (k * 2 * Math.PI) / n, cu = Math.cos(a) * ru, cv = Math.sin(a) * rv;
    out.push([c[0] + e1.x * cu + e2.x * cv, c[1] + e1.y * cu + e2.y * cv, c[2] + e1.z * cu + e2.z * cv]);
  }
  return out;
}

const rect = (axis, hu, hv, c) => ringAxis(axis, 4, hu * Math.SQRT2, hv * Math.SQRT2, c, Math.PI / 4);

function band(out, lo, hi) {
  const n = lo.length;
  for (let k = 0; k < n; k++) { const j = (k + 1) % n; quad(out, lo[k], hi[k], hi[j], lo[j]); }
}
function capTop(out, r) { for (let k = 1; k < r.length - 1; k++) tri(out, r[0], r[k + 1], r[k]); }
function capBot(out, r) { for (let k = 1; k < r.length - 1; k++) tri(out, r[0], r[k], r[k + 1]); }

function annulusUp(out, inner, outer) {
  const n = inner.length;
  for (let k = 0; k < n; k++) { const j = (k + 1) % n; quad(out, outer[k], inner[k], inner[j], outer[j]); }
}
function annulusDown(out, inner, outer) {
  const n = inner.length;
  for (let k = 0; k < n; k++) { const j = (k + 1) % n; quad(out, inner[k], outer[k], outer[j], inner[j]); }
}

function strut(out, p0, p1, hu, hv) {
  const d = [p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]];
  band(out, ringDir(d, 4, hu * Math.SQRT2, hv * Math.SQRT2, p0, Math.PI / 4),
            ringDir(d, 4, hu * Math.SQRT2, hv * Math.SQRT2, p1, Math.PI / 4));
}
const boxG = (hx, hy, hz, x, y, z) => new THREE.BoxGeometry(hx * 2, hy * 2, hz * 2).translate(x, y, z);

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
  const m = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  if (!m) throw new Error('mergeGeometries returned null (attribute mismatch)');
  m.computeVertexNormals();
  return m;
}

const H0        = 2.60;
const KINK_F    = 0.331;
const R_KINK    = 0.101;
const R_TOP     = 0.081;
const R_CAP     = 0.062;
const R_SPLAY   = 0.079;
const CAP_DROP  = 0.055;
const SPLAY_EXP = 1.35;

const ARM_TOP   = 0.150;
const ARM_BOT   = 0.280;
const BRACE_FT  = 0.590;
const ARM_HX    = 0.055;
const ARM_HY    = 0.065;
const ARM_NOSE  = 0.055;
const HANG_BACK = 0.138;

const L = {
  hangTop: 0.005, hangBot: -0.110, hangHX: 0.048, hangHZ: 0.052,
  peakY: -0.104, peakHW: 0.075,
  crestY: -0.208, crestHW: 0.255,
  eaveY: -0.320, eaveHW: 0.212,
  collarTopY: -0.315, collarBotY: -0.362, collarHW: 0.196,
  cageTopY: -0.352, cageBotY: -0.710,
  cageHWTop: 0.196, cageHWBot: 0.142,
  barHW: 0.026, glassInset: 0.030,
  botTopY: -0.700, botBotY: -0.745, botHW: 0.146,
  plinth: [[-0.745, 0.146], [-0.762, 0.168], [-0.818, 0.168], [-0.856, 0.118]],
};

function resolve(user) {
  const cw = COLORWAYS[user.colorway] || COLORWAYS[params.colorway.default];
  const C = {};
  for (const k of ['post', 'postCap', 'iron', 'roof', 'pane']) {
    C[k] = user[k] !== undefined ? user[k] : (cw[k] !== undefined ? cw[k] : params[k].default);
  }
  const num = (k) => {
    const v = user[k] !== undefined ? Number(user[k]) : params[k].default;
    return Math.min(params[k].max, Math.max(params[k].min, v));
  };
  return { C, tallness: num('tallness'), flare: num('flare'), armReach: num('armReach'), lanternSize: num('lanternSize') };
}

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const C = P.C;
  const S = P.lanternSize;

  const g = new THREE.Group();
  g.name = 'dock-lantern-post';

  const H = H0 * P.tallness;
  const kinkY = KINK_F * H;
  const topY = H - CAP_DROP;
  const rBase = R_KINK + R_SPLAY * P.flare;

  const postR = (y) => {
    if (y >= topY) return R_TOP + (R_CAP - R_TOP) * ((y - topY) / CAP_DROP);
    if (y >= kinkY) return R_KINK + (R_TOP - R_KINK) * ((y - kinkY) / (topY - kinkY));
    return R_KINK + (rBase - R_KINK) * Math.pow((kinkY - y) / kinkY, SPLAY_EXP);
  };

  const postZ = (y) => -0.010 * Math.min(1, y / H) * (y / H);
  const postFace = (y) => postR(y) * Math.cos(Math.PI / 8) + postZ(y);

  const armTip = Math.max(P.armReach, 0.135 + (L.crestHW + HANG_BACK) * S);
  const armY = H - (ARM_TOP + ARM_BOT) / 2;
  const zHang = armTip - HANG_BACK * S;

  const st = [];

  const rows = [0, 0.35 * kinkY, kinkY, topY, H];
  const rings = rows.map((y) => ringAxis('y', 8, postR(y), postR(y), [0, y, postZ(y)], Math.PI / 8));
  {
    const pos = [];
    for (let i = 0; i < rings.length - 1; i++) band(pos, rings[i], rings[i + 1]);
    capBot(pos, rings[0]);
    st.push({ g: posGeo(pos), c: C.post });
  }
  { const pos = []; capTop(pos, rings[rings.length - 1]); st.push({ g: posGeo(pos), c: C.postCap }); }

  {
    const y0 = H - 0.640, y1 = H - 0.140, ym = (y0 + y1) / 2;

    st.push({ g: boxG(0.048, (y1 - y0) / 2, 0.014, 0, ym, postFace(ym) + 0.005), c: C.iron });

    const yp = H - 0.550, zBack = -postFace(yp) + postZ(yp) * 2;
    const pos = [];
    const out = rect('z', 0.030, 0.042, [0, yp, zBack - 0.020]);
    band(pos, out, rect('z', 0.030, 0.042, [0, yp, zBack + 0.030]));
    capBot(pos, out);
    st.push({ g: posGeo(pos), c: C.iron });
  }

  {
    const zIn = postFace(armY) - 0.045, zOut = armTip;
    const a = rect('z', ARM_HX, ARM_HY, [0, armY, zIn]);
    const b = rect('z', ARM_HX, ARM_HY, [0, armY, zOut - ARM_NOSE]);
    const c = rect('z', ARM_HX * 0.68, ARM_HY * 0.70, [0, armY, zOut]);
    const pos = [];
    band(pos, a, b); band(pos, b, c); capTop(pos, c);
    st.push({ g: posGeo(pos), c: C.iron });
  }

  {
    const yFoot = H - BRACE_FT;
    const p0 = [0, yFoot - 0.02, postFace(yFoot) - 0.02];
    const p1 = [0, H - ARM_BOT + 0.02, armTip * 0.675];
    const pos = []; strut(pos, p0, p1, 0.038, 0.030);
    st.push({ g: posGeo(pos), c: C.iron });
  }

  const mat = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });
  const postMesh = new THREE.Mesh(mergeColored(st), mat);
  postMesh.name = 'post-bracket';
  g.add(postMesh);

  const ln = [];
  const rY = (hw, y) => rect('y', hw, hw, [0, y, 0]);

  {
    const lo = rect('y', L.hangHX, L.hangHZ, [0, L.hangBot, 0]);
    const hi = rect('y', L.hangHX, L.hangHZ, [0, L.hangTop, 0]);
    const pos = []; band(pos, lo, hi); capTop(pos, hi);
    ln.push({ g: posGeo(pos), c: C.iron });
  }

  {
    const peak = rY(L.peakHW, L.peakY), crest = rY(L.crestHW, L.crestY);
    const eave = rY(L.eaveHW, L.eaveY),  soffit = rY(L.collarHW - 0.006, L.eaveY);
    const pos = [];
    band(pos, crest, peak); capTop(pos, peak);
    band(pos, eave, crest);
    annulusDown(pos, soffit, eave);
    ln.push({ g: posGeo(pos), c: C.roof });
  }

  {
    const lo = rY(L.collarHW, L.collarBotY), hi = rY(L.collarHW, L.collarTopY);
    const pos = []; band(pos, lo, hi); capBot(pos, lo);
    ln.push({ g: posGeo(pos), c: C.iron });
  }

  {
    const oTop = L.cageHWTop - L.barHW, oBot = L.cageHWBot - L.barHW;
    for (const sx of [1, -1]) for (const sz of [1, -1]) {
      const pos = [];
      strut(pos, [sx * oBot, L.cageBotY, sz * oBot], [sx * oTop, L.cageTopY, sz * oTop], L.barHW, L.barHW);
      ln.push({ g: posGeo(pos), c: C.iron });
    }
  }

  {
    const gt = L.cageHWTop - L.glassInset, gb = L.cageHWBot - L.glassInset;
    const pos = [];
    band(pos, rY(gb, L.cageBotY), rY(gt, L.cageTopY));
    ln.push({ g: posGeo(pos), c: C.pane });
  }

  {
    const pos = [];
    const top = rY(L.botHW, L.botTopY);
    band(pos, rY(L.botHW, L.botBotY), top);
    capTop(pos, top);
    for (let i = 0; i < L.plinth.length - 1; i++) {
      const [y0, w0] = L.plinth[i], [y1, w1] = L.plinth[i + 1];
      band(pos, rY(w1, y1), rY(w0, y0));
    }
    const last = L.plinth[L.plinth.length - 1];
    capBot(pos, rY(last[1], last[0]));
    ln.push({ g: posGeo(pos), c: C.iron });
  }

  const lantern = new THREE.Group();
  lantern.name = 'lantern';
  lantern.position.set(0, H - ARM_BOT, zHang);
  const lanGeo = mergeColored(ln);
  lanGeo.applyMatrix4(new THREE.Matrix4().makeScale(S, S, S));
  const lanMesh = new THREE.Mesh(lanGeo, mat);
  lanMesh.name = 'lantern-head';
  lantern.add(lanMesh);
  g.add(lantern);

  const box = new THREE.Box3().setFromObject(g);
  const dx = (box.min.x + box.max.x) / 2, dz = (box.min.z + box.max.z) / 2, dy = box.min.y;
  for (const ch of g.children) { ch.position.x -= dx; ch.position.y -= dy; ch.position.z -= dz; }

  return g;
}

export const rig = {

  'lantern': { axis: 'x', range: [0, -22] },
};
export const detach = ['lantern'];
export const night = {
  pane: { color: '#FFD08A', intensity: 0.85, describe: 'oil flame behind the amber lantern glass' },
};

export default createAsset;
