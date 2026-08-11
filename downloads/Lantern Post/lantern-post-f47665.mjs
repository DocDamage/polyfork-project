/*
 * Lantern Post
 * https://polyfork.dev/asset/lantern-post-f47665
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './lantern-post-f47665.mjs';
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
 *   colorway     choice  'oak-lantern'  'oak-lantern' | 'weathered-grey' | 'creosote-pine' | 'ranger-green'
 *   timber       color   '#8c6a47'      any hex or THREE.Color
 *   endGrain     color   '#c2a479'      any hex or THREE.Color
 *   frame        color   '#a5855e'      any hex or THREE.Color
 *   roof         color   '#75563b'      any hex or THREE.Color
 *   iron         color   '#57544e'      any hex or THREE.Color
 *   pane         color   '#f4ece0'      any hex or THREE.Color
 *   postHeight   range   2.4            1.75 to 2.56
 *   timberGirth  range   1              0.75 to 1.35
 *   armReach     range   0.6            0.42 to 0.92
 *   chainLinks   range   4              2 to 5
 *   lanternSize  range   1              0.8 to 1.22
 *
 * Every option is described in full at https://polyfork.dev/cdn/lantern-post-f47665-params.json
 *
 * SPECS  482 triangles, 1 material, 0.47 x 2.4 x 0.93 m (real-world scale).
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
  'oak-lantern':     { timber: '#8c6a47', endGrain: '#c2a479', frame: '#a5855e', roof: '#75563b', iron: '#57544e', pane: '#f4ece0' },
  'weathered-grey':  { timber: '#87847c', endGrain: '#bcb9b1', frame: '#a3a099', roof: '#6e6b63', iron: '#3a2a1e', pane: '#e0d2b4' },
  'creosote-pine':   { timber: '#4a3527', endGrain: '#8c6a47', frame: '#75563b', roof: '#3a2a1e', iron: '#57544e', pane: '#f4ece0' },
  'ranger-green':    { timber: '#5d4430', endGrain: '#a5855e', frame: '#75563b', roof: '#25402c', iron: '#3f4d55', pane: '#e0d2b4' },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'oak-lantern', label: 'Colorway', affects: 'colors',
    options: ['oak-lantern', 'weathered-grey', 'creosote-pine', 'ranger-green'],
    describe: 'Curated Nature & Forest scheme. oak-lantern is the default warm oak post with a mid-brown roof, pale cream panes and near-black iron; weathered-grey is a silvered driftwood post with pewter hardware and warm cream panes; creosote-pine is a dark tarred post with a near-black roof and bright panes for maximum contrast; ranger-green is a mid-brown post under a deep forest-green painted lamp cap with blue-grey iron.',
  },
  timber: {
    type: 'color', default: '#8c6a47', label: 'Post timber', affects: 'colors',
    describe: 'Albedo of every rough structural timber: the post shaft and its head chamfer, the cross-arm, the back stub and the knee brace. This is the dominant mass and it is ONE material, so the facet-to-facet tone differences you see in the refs come from scene lighting, not from a second wood colour here.',
  },
  endGrain: {
    type: 'color', default: '#c2a479', label: 'Sawn end grain', affects: 'colors',
    describe: 'Albedo of the three cut faces: the post head top and the two chamfered arm noses. A real material change (cut end grain against planed side grain), so keep it a clear step LIGHTER than the timber or the chamfered head stops reading as a saw cut.',
  },
  frame: {
    type: 'color', default: '#a5855e', label: 'Lantern frame', affects: 'colors',
    describe: 'Albedo of the lantern housing joinery: the four proud corner posts standing over the panes, the plinth rim ledge, its fascia and the tapered foot. One rung lighter than the post timber so the hanging lamp separates from the post behind it; darker than the timber and the lantern sinks into the post in the hero view.',
  },
  roof: {
    type: 'color', default: '#75563b', label: 'Lantern roof', affects: 'colors',
    describe: 'Albedo of the pyramidal roof cap, its downturned eave fascia and the soffit under the overhang. The darkest wood-family zone, so the wide eave line reads as a hard horizontal band across the top of the lamp at thumbnail size.',
  },
  iron: {
    type: 'color', default: '#57544e', label: 'Ironwork', affects: 'colors',
    describe: 'Albedo of every piece of hardware: the staple under the arm, all four chain links and the eight bolt bosses on the plinth. Dark desaturated grey reads as forged iron; anything lighter than the timber inverts the value ladder and the chain dissolves into the post behind it.',
  },
  pane: {
    type: 'color', default: '#f4ece0', label: 'Glass pane', affects: 'colors',
    describe: 'Albedo of the four recessed glass panes by DAY — pale, opaque, the lightest zone on the asset. This is also the only surface `night` lights up, so it must stay its own colour and never share a hex with the frame around it or a consumer switching the lamp on will light the joinery too.',
  },
  postHeight: {
    type: 'range', default: 2.40, min: 1.75, max: 2.56, affects: 'geometry', label: 'Post height',
    describe: 'Height of the post in metres, measured ground to head. REBUILT, not scaled: the timber SECTION, the chamfers, the arm, the brace, the chain and the whole lamp head keep their exact built size at every value and simply ride at fixed offsets below the head, so only the post length changes. At 1.75 it is a low path marker whose lamp hangs at waist height and the head furniture nearly fills the post; at 2.40 it is the reference roadside post; at 2.56 it is a tall clearing lamp. The range is skewed downward on purpose so the tall end still fits the proof camera.',
  },
  timberGirth: {
    type: 'range', default: 1.0, min: 0.75, max: 1.35, affects: 'geometry', label: 'Timber girth',
    describe: 'Cross-section of the whole timber frame, as a multiple of the reference. At 0.75 the post is a slim 0.139 m stake with a light arm and a spindly brace; at 1.0 it is the reference 0.185 m post; at 1.35 it is a 0.250 m baulk that reads as a heavy gatepost. The post, arm and brace all move together and keep their proportions to one another, the arrises keep their 19%-of-section chamfer, and heights and reaches do not change — only the sections do.',
  },
  armReach: {
    type: 'range', default: 0.60, min: 0.42, max: 0.92, affects: 'geometry', label: 'Arm reach',
    describe: 'Distance in metres from the post axis to the tip of the cross-arm, along +Z. At 0.42 the lantern tucks in tight over the post; at 0.60 it is the reference overhang; at 0.92 it swings a long way clear of the post to light a path. The knee brace, the staple, the chain and the lamp all follow the arm, the beam always overshoots the hang point by 0.135 m, and the reach is held out far enough that a big lamp on a fat post can never bite into the timber.',
  },
  chainLinks: {
    type: 'range', default: 4, min: 2, max: 5, step: 1, affects: 'geometry', label: 'Chain links',
    describe: 'How many iron links hang between the staple and the lamp. Each link is a real 48-triangle ring of 0.026 m stock at a constant 0.052 m pitch, so the count genuinely rebuilds the chain and the triangle total moves with it. At 2 the lamp is slung tight under the arm; at 4 it is the reference drop of 0.25 m; at 5 it hangs low and swings wide.',
  },
  lanternSize: {
    type: 'range', default: 1.0, min: 0.80, max: 1.22, affects: 'geometry', label: 'Lantern size',
    describe: 'Uniform size of the lamp head, built about the bottom link of the chain so it always hangs from the last link whatever the chain length. At 0.80 it is a compact 0.37 m lamp on a comparatively heavy post; at 1.0 it is the reference 0.47 m head; at 1.22 it is an oversized coaching lantern that dominates the post. The chain keeps its own stock size at every value.',
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
};

const sqPts = (h) => [[h, -h], [h, h], [-h, h], [-h, -h]];
const octPts = (h, c) => [
  [h, -(h - c)], [h, h - c], [h - c, h], [-(h - c), h],
  [-h, h - c], [-h, -(h - c)], [-(h - c), -h], [h - c, -h],
];
const place = (uv, e1, e2, ctr) => uv.map(([u, v]) => [
  ctr[0] + e1[0] * u + e2[0] * v,
  ctr[1] + e1[1] * u + e2[1] * v,
  ctr[2] + e1[2] * u + e2[2] * v,
]);
const ring = (axis, uv, ctr) => place(uv, BASIS[axis][0], BASIS[axis][1], ctr);

function frameDir(d) {
  const D = new THREE.Vector3(d[0], d[1], d[2]).normalize();
  const tmp = Math.abs(D.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
  const e1 = new THREE.Vector3().crossVectors(D, tmp).normalize();
  const e2 = new THREE.Vector3().crossVectors(D, e1).negate();
  return [[e1.x, e1.y, e1.z], [e2.x, e2.y, e2.z]];
}
function band(out, lo, hi) {
  const n = lo.length;
  for (let k = 0; k < n; k++) { const j = (k + 1) % n; quad(out, lo[k], hi[k], hi[j], lo[j]); }
}
function capTop(out, r) { for (let k = 1; k < r.length - 1; k++) tri(out, r[0], r[k + 1], r[k]); }
function capBot(out, r) { for (let k = 1; k < r.length - 1; k++) tri(out, r[0], r[k], r[k + 1]); }

function strut(out, p0, p1, uv) {
  const [e1, e2] = frameDir([p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]]);
  band(out, place(uv, e1, e2, p0), place(uv, e1, e2, p1));
}

function rivet(c, n, r, h) {
  const N = new THREE.Vector3(n[0], n[1], n[2]).normalize();
  const up = Math.abs(N.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
  const t = new THREE.Vector3().crossVectors(up, N).normalize();
  const b = new THREE.Vector3().crossVectors(N, t).normalize();
  const apex = [c[0] + N.x * h, c[1] + N.y * h, c[2] + N.z * h];
  const rg = [];
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * Math.PI * 2, cs = Math.cos(a) * r, sn = Math.sin(a) * r;
    rg.push([c[0] + t.x * cs + b.x * sn, c[1] + t.y * cs + b.y * sn, c[2] + t.z * cs + b.z * sn]);
  }
  const pos = [];
  for (let i = 0; i < 6; i++) tri(pos, apex, rg[i], rg[(i + 1) % 6]);
  return posGeo(pos);
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
  const m = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  if (!m) throw new Error('mergeGeometries returned null (attribute mismatch)');
  m.computeVertexNormals();
  return m;
}

const POST_HW   = 0.0925;
const ARM_HW    = 0.0750;
const BRACE_HW  = 0.0520;
const CHAM      = 0.19;
const HEAD_RISE = 0.055;
const HEAD_IN   = 0.62;

const ARM_DROP  = 0.150;
const ARM_BACK  = 0.235;
const ARM_NOSE  = 0.048;
const NOSE_IN   = 0.66;
const HANG_BACK = 0.135;
const BRACE_FT  = 0.270;
const BRACE_RUN = 0.530;

const LINK_R    = 0.028;
const LINK_W    = 0.013;
const LINK_PITCH = 0.052;
const LINK_TOP  = 0.070;

const LP = {
  apex:  [0.000, 0.044],
  mid:   [0.046, 0.146],
  eave:  [0.092, 0.234],
  fasc:  [0.131, 0.220],
  cageT: [0.131, 0.189],
  cageB: [0.390, 0.151],
  rimB:  [0.437, 0.184],
  foot:  [0.509, 0.080],
};
const RIM_HW    = 0.184;
const CORNER_HW = 0.036;
const PANE_IN   = 0.034;
const BOSS_OFF  = 0.105;

const ZONES = ['timber', 'endGrain', 'frame', 'roof', 'iron', 'pane'];

function resolve(user) {
  const cw = COLORWAYS[user.colorway] || COLORWAYS[params.colorway.default];
  const C = {};
  for (const k of ZONES) {
    C[k] = user[k] !== undefined ? user[k] : (cw[k] !== undefined ? cw[k] : params[k].default);
  }
  const num = (k) => {
    const v = user[k] !== undefined ? Number(user[k]) : params[k].default;
    if (!Number.isFinite(v)) return params[k].default;
    return Math.min(params[k].max, Math.max(params[k].min, v));
  };
  return {
    C,
    postHeight: num('postHeight'),
    girth: num('timberGirth'),
    armReach: num('armReach'),
    links: Math.round(num('chainLinks')),
    size: num('lanternSize'),
  };
}

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const C = P.C;
  const S = P.size;
  const G = P.girth;

  const g = new THREE.Group();
  g.name = 'lantern-post';

  const H  = P.postHeight;
  const hp = POST_HW * G, ha = ARM_HW * G, hb = BRACE_HW * G;
  const armTop = H - ARM_DROP;
  const armBot = armTop - 2 * ha;
  const armCy  = armTop - ha;

  const hangZ = Math.max(P.armReach - HANG_BACK, hp + LP.eave[1] * S + 0.035);
  const armTip = hangZ + HANG_BACK;

  const mat = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  const st = [];

  {
    const sec = octPts(hp, hp * CHAM);
    const r0 = ring('y', sec, [0, 0, 0]);
    const r1 = ring('y', sec, [0, H - HEAD_RISE, 0]);
    const r2 = ring('y', octPts(hp * HEAD_IN, hp * HEAD_IN * CHAM), [0, H, 0]);
    const pos = [];
    band(pos, r0, r1); band(pos, r1, r2);
    capBot(pos, r0);
    st.push({ g: posGeo(pos), c: C.timber });
    const cap = []; capTop(cap, r2);
    st.push({ g: posGeo(cap), c: C.endGrain });
  }

  {
    const sec = octPts(ha, ha * CHAM);
    const nose = octPts(ha * NOSE_IN, ha * NOSE_IN * CHAM);
    const zs = [-ARM_BACK, -ARM_BACK + ARM_NOSE, armTip - ARM_NOSE, armTip];
    const rs = [
      ring('z', nose, [0, armCy, zs[0]]),
      ring('z', sec,  [0, armCy, zs[1]]),
      ring('z', sec,  [0, armCy, zs[2]]),
      ring('z', nose, [0, armCy, zs[3]]),
    ];
    const pos = [];
    for (let i = 0; i < 3; i++) band(pos, rs[i], rs[i + 1]);
    st.push({ g: posGeo(pos), c: C.timber });
    const caps = [];
    capBot(caps, rs[0]);
    capTop(caps, rs[3]);
    st.push({ g: posGeo(caps), c: C.endGrain });
  }

  {
    const zHead = Math.min(BRACE_RUN * armTip, armTip - 0.10);
    const pos = [];
    strut(pos, [0, armBot - BRACE_FT, hp - 0.030], [0, armBot + 0.035, zHead],
          octPts(hb, hb * CHAM));
    st.push({ g: posGeo(pos), c: C.timber });
  }

  {
    const lo = ring('y', sqPts(0.030), [0, armBot - 0.048, hangZ]);
    const hi = ring('y', sqPts(0.030), [0, armBot + 0.015, hangZ]);
    const pos = [];
    band(pos, lo, hi);
    capBot(pos, lo);
    st.push({ g: posGeo(pos), c: C.iron });
  }

  const postMesh = new THREE.Mesh(mergeColored(st), mat);
  postMesh.name = 'post-frame';
  g.add(postMesh);

  const ln = [];

  for (let i = 0; i < P.links; i++) {
    const t = new THREE.TorusGeometry(LINK_R, LINK_W, 4, 6);
    if (i % 2) t.rotateY(Math.PI / 2);
    t.translate(0, -(LINK_TOP + i * LINK_PITCH), 0);
    ln.push({ g: t, c: C.iron });
  }

  const topY = -(LINK_TOP + (P.links - 1) * LINK_PITCH + LINK_R + LINK_W) + 0.014;

  const LY = (k) => topY - LP[k][0] * S;
  const LH = (k) => LP[k][1] * S;
  const rY = (h, y) => ring('y', sqPts(h), [0, y, 0]);

  {
    const apex = rY(LH('apex'), LY('apex'));
    const mid  = rY(LH('mid'),  LY('mid'));
    const eave = rY(LH('eave'), LY('eave'));
    const fasc = rY(LH('fasc'), LY('fasc'));
    const pos = [];
    band(pos, mid, apex); capTop(pos, apex);
    band(pos, eave, mid);
    band(pos, fasc, eave);
    capBot(pos, fasc);
    ln.push({ g: posGeo(pos), c: C.roof });
  }

  {
    const oT = LH('cageT') - CORNER_HW * S, oB = LH('cageB') - CORNER_HW * S;
    const sec = sqPts(CORNER_HW * S);
    const eT = LY('cageT') + 0.010 * S, eB = LY('cageB') - 0.010 * S;
    for (const sx of [1, -1]) for (const sz of [1, -1]) {
      const pos = [];
      strut(pos, [sx * oB, eB, sz * oB], [sx * oT, eT, sz * oT], sec);
      ln.push({ g: posGeo(pos), c: C.frame });
    }
  }

  {
    const pos = [];
    band(pos, rY(LH('cageB') - PANE_IN * S, LY('cageB') - 0.008 * S),
              rY(LH('cageT') - PANE_IN * S, LY('cageT') + 0.008 * S));
    ln.push({ g: posGeo(pos), c: C.pane });
  }

  {
    const rimT = rY(RIM_HW * S, LY('cageB'));
    const rimB = rY(RIM_HW * S, LY('rimB'));
    const foot = rY(LH('foot'), LY('foot'));
    const pos = [];
    capTop(pos, rimT);
    band(pos, rimB, rimT);
    band(pos, foot, rimB);
    capBot(pos, foot);
    ln.push({ g: posGeo(pos), c: C.frame });
  }

  {
    const y = (LY('cageB') + LY('rimB')) / 2;
    const f = (RIM_HW - 0.004) * S;
    const r = 0.019 * S, hgt = 0.016 * S;
    for (const o of [-BOSS_OFF * S, 0, BOSS_OFF * S]) for (const s of [1, -1]) {
      ln.push({ g: rivet([s * f, y, o], [s, 0, 0], r, hgt), c: C.iron });
      ln.push({ g: rivet([o, y, s * f], [0, 0, s], r, hgt), c: C.iron });
    }
  }

  const lantern = new THREE.Group();
  lantern.name = 'lantern';
  lantern.position.set(0, armBot, hangZ);
  const lanMesh = new THREE.Mesh(mergeColored(ln), mat);
  lanMesh.name = 'lantern-head';
  lantern.add(lanMesh);
  g.add(lantern);

  const box = new THREE.Box3().setFromObject(g);
  const dx = (box.min.x + box.max.x) / 2, dz = (box.min.z + box.max.z) / 2, dy = box.min.y;
  for (const ch of g.children) { ch.position.x -= dx; ch.position.y -= dy; ch.position.z -= dz; }

  return g;
}

export const rig = {

  'lantern': { axis: 'z', range: [0, 26] },
};
export const detach = ['lantern'];
export const night = {
  pane: { color: '#ffd9a0', intensity: 0.85, describe: 'warm oil flame behind the four glass panes' },
};

export default createAsset;
