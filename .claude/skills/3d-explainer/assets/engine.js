/* ============================================================
   3D engine — consumes window.EXPLAINER_DATA {zones, nodes, edges, flows, ghosts}
   Built on THREE r147 (inlined above) + OrbitControls.
   ============================================================ */
(function () {
  'use strict';
  const D = window.EXPLAINER_DATA;
  const container = document.getElementById('scene');
  const labelLayer = document.getElementById('labels');

  // ---------- renderer / scene / camera ----------
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.outputEncoding = THREE.sRGBEncoding;
  container.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0xeef2f7);
  scene.fog = new THREE.Fog(0xeef2f7, 340, 640);

  const camera = new THREE.PerspectiveCamera(46, window.innerWidth / window.innerHeight, 1, 1200);
  camera.position.set(150, 128, 225);

  const controls = new THREE.OrbitControls(camera, renderer.domElement);
  controls.target.set(-5, 10, 8);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;
  controls.maxPolarAngle = Math.PI * 0.52;
  controls.minDistance = 30;
  controls.maxDistance = 420;
  controls.autoRotateSpeed = 0.55;

  const hemi = new THREE.HemisphereLight(0xffffff, 0xd7dee9, 0.95);
  scene.add(hemi);
  const dir = new THREE.DirectionalLight(0xffffff, 0.65);
  dir.position.set(80, 140, 60);
  scene.add(dir);
  const dir2 = new THREE.DirectionalLight(0xdbe7ff, 0.25);
  dir2.position.set(-90, 60, -80);
  scene.add(dir2);

  // subtle ground disc far below, for depth
  const ground = new THREE.Mesh(
    new THREE.CircleGeometry(420, 64),
    new THREE.MeshBasicMaterial({ color: 0xe4e9f2 })
  );
  ground.rotation.x = -Math.PI / 2;
  ground.position.y = -46;
  scene.add(ground);

  // ---------- helpers ----------
  const V3 = (x, y, z) => new THREE.Vector3(x, y, z);
  const zonesById = {}, nodesById = {}, edgesById = {};
  const nodeMeshes = [];          // raycast targets
  const dimmables = [];           // {mat, baseOpacity}
  function trackMat(mat, baseOpacity) {
    mat.transparent = true;
    mat.opacity = baseOpacity;
    dimmables.push({ mat, base: baseOpacity });
    return mat;
  }

  // ---------- zones (floating platforms) ----------
  for (const z of D.zones) {
    zonesById[z.id] = z;
    const g = new THREE.Group();
    const plate = new THREE.Mesh(
      new THREE.BoxGeometry(z.w, 1.6, z.d),
      trackMat(new THREE.MeshLambertMaterial({ color: z.color }), 0.92)
    );
    plate.position.set(0, -0.8, 0);
    g.add(plate);
    const rim = new THREE.LineSegments(
      new THREE.EdgesGeometry(new THREE.BoxGeometry(z.w, 1.6, z.d)),
      trackMat(new THREE.LineBasicMaterial({ color: 0xb9c2d0 }), 0.65)
    );
    rim.position.copy(plate.position);
    g.add(rim);
    g.position.set(z.x, z.y, z.z);
    scene.add(g);
    z._group = g;

    const lbl = document.createElement('div');
    lbl.className = 'lbl zone';
    lbl.textContent = z.label;
    labelLayer.appendChild(lbl);
    z._lbl = lbl;
    z._lblAnchor = V3(z.x - z.w / 2 + 6, z.y + 1.5, z.z - z.d / 2 + 4);
  }

  // ---------- nodes ----------
  function buildNodeMesh(n) {
    const zone = zonesById[n.zone];
    const color = new THREE.Color(n.color || '#8899aa');
    const group = new THREE.Group();
    const w = n.w || 10, h = n.h || 7, d = n.d || 10;

    if (n.kind === 'fleet') {
      // grid of small cubes = the repl fleet
      const cols = n.cols || 6, rows = n.rows || 4, gap = 1.4;
      const cw = (w - gap * (cols - 1)) / cols, cd = (d - gap * (rows - 1)) / rows;
      let i = 0;
      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
          const hot = (n.hotIndex !== undefined && i === n.hotIndex);
          const ch = hot ? h * 1.5 : h * (0.55 + 0.3 * Math.abs(Math.sin(i * 2.7)));
          const m = new THREE.Mesh(
            new THREE.BoxGeometry(cw, ch, cd),
            trackMat(new THREE.MeshLambertMaterial({ color: hot ? new THREE.Color(n.hotColor || '#f59e0b') : color }), 1)
          );
          m.position.set(-w / 2 + cw / 2 + c * (cw + gap), ch / 2, -d / 2 + cd / 2 + r * (cd + gap));
          group.add(m);
          i++;
        }
      }
    } else if (n.kind === 'db') {
      const m = new THREE.Mesh(
        new THREE.CylinderGeometry(w / 2, w / 2, h, 28),
        trackMat(new THREE.MeshLambertMaterial({ color }), 1)
      );
      m.position.y = h / 2;
      group.add(m);
      for (const fy of [0.35, 0.7]) {
        const ring = new THREE.Mesh(
          new THREE.TorusGeometry(w / 2 + 0.06, 0.14, 8, 40),
          trackMat(new THREE.MeshBasicMaterial({ color: 0xffffff }), 0.75)
        );
        ring.rotation.x = Math.PI / 2;
        ring.position.y = h * fy;
        group.add(ring);
      }
    } else if (n.kind === 'client') {
      // slim upright card, like a chat window
      const m = new THREE.Mesh(
        new THREE.BoxGeometry(w, h, 1.6),
        trackMat(new THREE.MeshLambertMaterial({ color }), 1)
      );
      m.position.y = h / 2;
      group.add(m);
      const screen = new THREE.Mesh(
        new THREE.PlaneGeometry(w * 0.78, h * 0.66),
        trackMat(new THREE.MeshBasicMaterial({ color: 0xffffff }), 0.9)
      );
      screen.position.set(0, h * 0.55, 0.85);
      group.add(screen);
    } else {
      // default: building box + edge outline (+ optional antenna for token minters)
      const m = new THREE.Mesh(
        new THREE.BoxGeometry(w, h, d),
        trackMat(new THREE.MeshLambertMaterial({ color }), 1)
      );
      m.position.y = h / 2;
      group.add(m);
      const rim = new THREE.LineSegments(
        new THREE.EdgesGeometry(new THREE.BoxGeometry(w, h, d)),
        trackMat(new THREE.LineBasicMaterial({ color: color.clone().multiplyScalar(0.55) }), 0.9)
      );
      rim.position.y = h / 2;
      group.add(rim);
      if (n.antenna) {
        const pole = new THREE.Mesh(
          new THREE.CylinderGeometry(0.18, 0.18, 4.4, 8),
          trackMat(new THREE.MeshBasicMaterial({ color: 0x6b7280 }), 1)
        );
        pole.position.y = h + 2.2;
        group.add(pole);
        const tip = new THREE.Mesh(
          new THREE.SphereGeometry(0.85, 14, 10),
          trackMat(new THREE.MeshBasicMaterial({ color: n.antennaColor || '#f59e0b' }), 1)
        );
        tip.position.y = h + 4.6;
        group.add(tip);
        n._tip = tip;
      }
    }

    group.position.set(zone.x + n.x, zone.y, zone.z + n.z);
    group.traverse((o) => { if (o.isMesh) { o.userData.nodeId = n.id; nodeMeshes.push(o); } });
    scene.add(group);
    n._group = group;
    n._top = V3(zone.x + n.x, zone.y + (n.kind === 'fleet' ? (n.h || 7) * 1.6 : (n.h || 7)), zone.z + n.z);
    n._anchor = n._top.clone().add(V3(0, 2.6, 0));
    n._center = V3(zone.x + n.x, zone.y + (n.h || 7) / 2, zone.z + n.z);
  }

  for (const n of D.nodes) { nodesById[n.id] = n; buildNodeMesh(n); }

  // ghost decorations (non-interactive, e.g. "more cells…")
  for (const gh of (D.ghosts || [])) {
    const m = new THREE.Mesh(
      new THREE.BoxGeometry(gh.w, gh.h, gh.d),
      trackMat(new THREE.MeshLambertMaterial({ color: gh.color || 0xb9c2d0 }), 0.28)
    );
    m.position.set(gh.x, gh.y + gh.h / 2, gh.z);
    scene.add(m);
    if (gh.label) {
      const lbl = document.createElement('div');
      lbl.className = 'lbl zone';
      lbl.textContent = gh.label;
      labelLayer.appendChild(lbl);
      gh._lbl = lbl;
      gh._lblAnchor = V3(gh.x, gh.y + gh.h + 3, gh.z);
    }
  }

  // ---------- node labels ----------
  for (const n of D.nodes) {
    const lbl = document.createElement('div');
    lbl.className = 'lbl';
    lbl.innerHTML = n.label + (n.sub ? '<small>' + n.sub + '</small>' : '');
    lbl.addEventListener('click', () => selectNode(n.id));
    labelLayer.appendChild(lbl);
    n._lbl = lbl;
  }

  // ---------- edges ----------
  const EDGE_STYLE = D.edgeStyles || {};
  function edgeCurve(e) {
    const a = nodesById[e.from]._top.clone();
    const b = nodesById[e.to]._top.clone();
    const mid = a.clone().lerp(b, 0.5);
    const dist = a.distanceTo(b);
    mid.y += (e.arc !== undefined ? e.arc : dist * 0.22 + 4);
    return new THREE.QuadraticBezierCurve3(a, mid, b);
  }
  for (const e of D.edges) {
    edgesById[e.id] = e;
    const style = EDGE_STYLE[e.kind] || { color: '#9aa5b4' };
    e._color = new THREE.Color(style.color);
    e._curve = edgeCurve(e);
    const tube = new THREE.Mesh(
      new THREE.TubeGeometry(e._curve, 40, 0.22, 7, false),
      trackMat(new THREE.MeshBasicMaterial({ color: e._color }), 0.34)
    );
    scene.add(tube);
    e._tube = tube;

    // ambient particles
    const count = e.ambient === false ? 0 : (e.particles || 3);
    if (count > 0) {
      const geo = new THREE.BufferGeometry();
      geo.setAttribute('position', new THREE.BufferAttribute(new Float32Array(count * 3), 3));
      const mat = new THREE.PointsMaterial({ color: e._color, size: 2.1, sizeAttenuation: true,
        transparent: true, opacity: 0.85, depthWrite: false });
      const pts = new THREE.Points(geo, mat);
      pts.frustumCulled = false;
      scene.add(pts);
      e._ambient = { pts, ts: Array.from({ length: count }, (_, i) => i / count) };
    }
  }

  // ---------- flow player ----------
  const flowButtons = document.getElementById('flow-buttons');
  const captionEl = document.getElementById('caption');
  let activeFlow = null, stepIdx = 0, stepT = 0, pulse = null, camTween = null;
  const STEP_SECONDS = 6.5;

  const pulseGeo = new THREE.BufferGeometry();
  pulseGeo.setAttribute('position', new THREE.BufferAttribute(new Float32Array(10 * 3), 3));
  const pulseMat = new THREE.PointsMaterial({ color: 0x2563eb, size: 5.2, sizeAttenuation: true,
    transparent: true, opacity: 0.95, depthWrite: false });
  pulse = new THREE.Points(pulseGeo, pulseMat);
  pulse.frustumCulled = false;
  pulse.visible = false;
  scene.add(pulse);

  function flowStepEdges(step) {
    const ids = step.edges || (step.edge ? [step.edge] : []);
    return ids.map((id) => edgesById[id]).filter(Boolean);
  }

  function setDimming() {
    if (!activeFlow) {
      for (const d of dimmables) d.mat.opacity = d.base;
      for (const n of D.nodes) n._lbl.classList.remove('dim', 'hot');
      for (const e of D.edges) { e._tube.material.opacity = 0.34; e._tube.material.color.copy(e._color); }
      return;
    }
    const hotNodes = new Set(), hotEdges = new Set();
    const steps = activeFlow.steps;
    for (let i = 0; i <= stepIdx && i < steps.length; i++) {
      for (const e of flowStepEdges(steps[i])) {
        hotEdges.add(e.id);
        hotNodes.add(e.from); hotNodes.add(e.to);
      }
      for (const nid of (steps[i].nodes || [])) hotNodes.add(nid);
    }
    const curEdges = new Set(flowStepEdges(steps[stepIdx]).map((e) => e.id));
    for (const n of D.nodes) {
      const on = hotNodes.has(n.id);
      n._lbl.classList.toggle('dim', !on);
      n._lbl.classList.toggle('hot', curEdges.size > 0 &&
        flowStepEdges(steps[stepIdx]).some((e) => e.from === n.id || e.to === n.id));
      n._group.traverse((o) => {
        if (o.isMesh || o.isLineSegments) o.material.opacity = on ? (o.material.userData?.zcBase ?? 1) : 0.13;
      });
    }
    // restore tracked base for participating nodes
    for (const d of dimmables) { if (d.mat.opacity !== 0.13) d.mat.opacity = d.base; }
    for (const n of D.nodes) {
      if (!hotNodes.has(n.id)) n._group.traverse((o) => { if (o.material) o.material.opacity = 0.13; });
    }
    for (const z of D.zones) z._group.traverse((o) => { if (o.material) o.material.opacity = o.material === undefined ? 1 : Math.min(o.material.opacity, 0.5); });
    for (const e of D.edges) {
      if (curEdges.has(e.id)) { e._tube.material.opacity = 0.95; e._tube.material.color.set(activeFlow.color || 0x2563eb); }
      else if (hotEdges.has(e.id)) { e._tube.material.opacity = 0.55; e._tube.material.color.copy(e._color); }
      else { e._tube.material.opacity = 0.06; e._tube.material.color.copy(e._color); }
    }
  }

  function focusStep(step) {
    const edges = flowStepEdges(step);
    if (!edges.length) return;
    const pts = [];
    for (const e of edges) { pts.push(nodesById[e.from]._center, nodesById[e.to]._center); }
    const box = new THREE.Box3().setFromPoints(pts);
    const center = box.getCenter(new THREE.Vector3());
    const size = box.getSize(new THREE.Vector3()).length();
    const dist = Math.max(60, size * 1.35);
    const dirV = camera.position.clone().sub(controls.target).normalize();
    camTween = {
      t: 0,
      fromT: controls.target.clone(), toT: center,
      fromP: camera.position.clone(), toP: center.clone().add(dirV.multiplyScalar(dist)).add(V3(0, dist * 0.18, 0)),
    };
  }

  function showCaption(step) {
    captionEl.style.display = 'block';
    captionEl.innerHTML = '<span class="step-n">' + (stepIdx + 1) + '/' + activeFlow.steps.length + '</span>' + step.caption +
      '<div style="margin-top:4px;font-size:11px;color:#9fb2d0">⟵ ⟶ step through · Esc to stop · auto-advances</div>';
  }

  function startFlow(flow, btn) {
    stopFlow();
    activeFlow = flow;
    stepIdx = 0; stepT = 0;
    btn.classList.add('active');
    flow._btn = btn;
    pulse.visible = true;
    pulseMat.color.set(flow.color || '#2563eb');
    controls.autoRotate = false;
    document.getElementById('toggle-rotate').checked = false;
    showCaption(flow.steps[0]);
    focusStep(flow.steps[0]);
    setDimming();
  }
  function stopFlow() {
    if (activeFlow && activeFlow._btn) activeFlow._btn.classList.remove('active');
    activeFlow = null;
    pulse.visible = false;
    captionEl.style.display = 'none';
    camTween = null;
    setDimming();
  }
  function gotoStep(i) {
    if (!activeFlow) return;
    if (i >= activeFlow.steps.length) { stopFlow(); return; }
    stepIdx = Math.max(0, i);
    stepT = 0;
    showCaption(activeFlow.steps[stepIdx]);
    focusStep(activeFlow.steps[stepIdx]);
    setDimming();
  }

  const flowBtnById = {}, flowById = {};
  for (const flow of D.flows) {
    const b = document.createElement('button');
    b.textContent = flow.label;
    b.addEventListener('click', () => {
      if (activeFlow === flow) stopFlow(); else startFlow(flow, b);
    });
    flowButtons.appendChild(b);
    flowBtnById[flow.id] = b;
    flowById[flow.id] = flow;
  }
  const sep = document.createElement('div'); sep.className = 'sep'; flowButtons.appendChild(sep);
  const stopBtn = document.createElement('button');
  stopBtn.textContent = '✕ stop';
  stopBtn.className = 'stop';
  stopBtn.addEventListener('click', stopFlow);
  flowButtons.appendChild(stopBtn);

  document.addEventListener('keydown', (ev) => {
    if (!activeFlow) return;
    if (ev.key === 'Escape') stopFlow();
    else if (ev.key === 'ArrowRight') gotoStep(stepIdx + 1);
    else if (ev.key === 'ArrowLeft') gotoStep(stepIdx - 1);
  });

  // ---------- selection panel ----------
  const panel = document.getElementById('panel');
  const raycaster = new THREE.Raycaster();
  const mouse = new THREE.Vector2();
  let downXY = null;
  renderer.domElement.addEventListener('pointerdown', (ev) => { downXY = [ev.clientX, ev.clientY]; camTween = null; });
  renderer.domElement.addEventListener('pointerup', (ev) => {
    if (!downXY) return;
    const moved = Math.hypot(ev.clientX - downXY[0], ev.clientY - downXY[1]);
    downXY = null;
    if (moved > 5) return; // was a drag
    mouse.x = (ev.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(ev.clientY / window.innerHeight) * 2 + 1;
    raycaster.setFromCamera(mouse, camera);
    const hits = raycaster.intersectObjects(nodeMeshes, false);
    if (hits.length) selectNode(hits[0].object.userData.nodeId);
    else panel.style.display = 'none';
  });
  renderer.domElement.addEventListener('pointermove', (ev) => {
    mouse.x = (ev.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(ev.clientY / window.innerHeight) * 2 + 1;
    raycaster.setFromCamera(mouse, camera);
    renderer.domElement.style.cursor = raycaster.intersectObjects(nodeMeshes, false).length ? 'pointer' : '';
  });
  panel.querySelector('.close').addEventListener('click', () => { panel.style.display = 'none'; });

  function selectNode(id) {
    const n = nodesById[id];
    if (!n) return;
    const zone = zonesById[n.zone];
    panel.querySelector('.kicker').textContent = n.kicker || zone.label;
    panel.querySelector('.kicker').style.color = n.color || '#5b6472';
    panel.querySelector('h2').textContent = n.label;
    panel.querySelector('.body').innerHTML = n.body || '';
    const pathsEl = panel.querySelector('.paths');
    pathsEl.innerHTML = (n.paths && n.paths.length)
      ? '<div>' + n.paths.join('</div><div>') + '</div>' : '';
    pathsEl.style.display = (n.paths && n.paths.length) ? 'block' : 'none';
    panel.style.display = 'block';
  }

  // ---------- legend ----------
  const zonesLegend = document.getElementById('legend-zones');
  for (const z of D.zones) {
    if (z.skipLegend) continue;
    const r = document.createElement('div');
    r.className = 'row';
    r.innerHTML = '<span class="chip" style="background:' + z.color + '"></span>' + z.label;
    zonesLegend.appendChild(r);
  }
  const trafficLegend = document.getElementById('legend-traffic');
  for (const [kind, st] of Object.entries(EDGE_STYLE)) {
    const r = document.createElement('div');
    r.className = 'row';
    r.innerHTML = '<span class="dot" style="background:' + st.color + '"></span>' + (st.label || kind);
    trafficLegend.appendChild(r);
  }
  document.getElementById('toggle-ambient').addEventListener('change', (ev) => {
    for (const e of D.edges) if (e._ambient) e._ambient.pts.visible = ev.target.checked;
  });
  document.getElementById('toggle-rotate').addEventListener('change', (ev) => {
    controls.autoRotate = ev.target.checked;
  });

  // ---------- deep links (#flow=create&step=4, #node=sts) ----------
  const fm = /flow=([\w-]+)(?:&step=(\d+))?/.exec(location.hash || '');
  if (fm && flowById[fm[1]]) {
    startFlow(flowById[fm[1]], flowBtnById[fm[1]]);
    if (fm[2]) gotoStep(Math.min(parseInt(fm[2], 10) - 1, flowById[fm[1]].steps.length - 1));
  }
  const nm = /node=([\w-]+)/.exec(location.hash || '');
  if (nm && nodesById[nm[1]]) selectNode(nm[1]);

  // ---------- comment-layer context hook ----------
  window.zcExtraContext = function () {
    if (activeFlow) return 'flow: ' + activeFlow.label + ' · step ' + (stepIdx + 1) + '/' + activeFlow.steps.length;
    const p = camera.position;
    return 'free orbit · cam(' + p.x.toFixed(0) + ',' + p.y.toFixed(0) + ',' + p.z.toFixed(0) + ')';
  };

  // ---------- animation loop ----------
  const tmp = new THREE.Vector3();
  function projectLabel(anchor, el, hideDist) {
    tmp.copy(anchor).project(camera);
    if (tmp.z > 1) { el.style.display = 'none'; return; }
    el.style.display = '';
    el.style.left = ((tmp.x * 0.5 + 0.5) * window.innerWidth) + 'px';
    el.style.top = ((-tmp.y * 0.5 + 0.5) * window.innerHeight) + 'px';
  }

  let last = performance.now();
  function tick(now) {
    requestAnimationFrame(tick);
    const dt = Math.max(0, Math.min(0.05, (now - last) / 1000));
    last = now;

    controls.update();

    // camera tween
    if (camTween) {
      camTween.t += dt / 1.1;
      const k = camTween.t >= 1 ? 1 : 1 - Math.pow(1 - camTween.t, 3);
      controls.target.lerpVectors(camTween.fromT, camTween.toT, k);
      camera.position.lerpVectors(camTween.fromP, camTween.toP, k);
      if (camTween.t >= 1) camTween = null;
    }

    // ambient particles
    for (const e of D.edges) {
      if (!e._ambient || !e._ambient.pts.visible) continue;
      const pos = e._ambient.pts.geometry.attributes.position;
      const dimmed = activeFlow && e._tube.material.opacity < 0.2;
      e._ambient.pts.material.opacity = dimmed ? 0.05 : 0.85;
      for (let i = 0; i < e._ambient.ts.length; i++) {
        e._ambient.ts[i] = (e._ambient.ts[i] + dt * 0.09) % 1;
        e._curve.getPoint(e._ambient.ts[i], tmp);
        pos.setXYZ(i, tmp.x, tmp.y, tmp.z);
      }
      pos.needsUpdate = true;
    }

    // flow pulse
    if (activeFlow) {
      stepT += dt;
      if (stepT > STEP_SECONDS) { gotoStep(stepIdx + 1); }
      if (activeFlow) {
        const step = activeFlow.steps[stepIdx];
        const edges = flowStepEdges(step);
        const pos = pulse.geometry.attributes.position;
        const N = 10;
        const cycle = (stepT % 2.0) / 2.0;
        for (let i = 0; i < N; i++) {
          const which = edges[i % edges.length];
          if (!which) break;
          let t = cycle - i * 0.035;
          if (t < 0) t += 1;
          if (step.dir === -1) t = 1 - t;
          which._curve.getPoint(t, tmp);
          pos.setXYZ(i, tmp.x, tmp.y, tmp.z);
        }
        pos.needsUpdate = true;
        pulse.material.opacity = 0.55 + 0.4 * Math.sin(now / 130);
      }
    }

    // antenna tips gently pulse (token minters)
    for (const n of D.nodes) {
      if (n._tip) n._tip.scale.setScalar(1 + 0.18 * Math.sin(now / 400 + n._tip.id));
    }

    if (/debug/.test(location.hash) && !tick._n) tick._n = 0;
    if (/debug/.test(location.hash) && ++tick._n % 5 === 0) {
      const w = nodesById['web']._group.children[0].material;
      console.log('DBG', JSON.stringify({ now: Math.round(now), cam: camera.position.toArray().map(Math.round),
        tgt: controls.target.toArray().map(Math.round), step: stepIdx, tween: !!camTween,
        webOp: w.opacity, plateOp: D.zones[0]._group.children[0].material.opacity }));
    }
    // labels
    for (const n of D.nodes) projectLabel(n._anchor, n._lbl);
    for (const z of D.zones) projectLabel(z._lblAnchor, z._lbl);
    for (const gh of (D.ghosts || [])) if (gh._lbl) projectLabel(gh._lblAnchor, gh._lbl);

    renderer.render(scene, camera);
  }
  requestAnimationFrame(tick);

  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });
})();
