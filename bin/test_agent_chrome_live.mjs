// Opens disposable blank Chrome windows. Requires the configured Hammerspoon module.
import assert from 'node:assert/strict';
import { spawn, execFileSync } from 'node:child_process';
import { once } from 'node:events';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { messages } from './agent-chrome.mjs';

const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const hs = code => execFileSync('/opt/homebrew/bin/hs', ['-q', '-t', '5', '-c', code], { encoding: 'utf8' }).trim();
const launcher = fileURLToPath(new URL('./agent-chrome', import.meta.url));
const probeName = `agentChromeCheck${process.pid}`;

for (const mode of ['Browser.close', 'SIGTERM', 'pipe close']) {
  const profile = mkdtempSync(tmpdir() + '/agent-chrome-check-');
  hs(`${probeName} = { pids = {} }; ${probeName}.timer = hs.timer.doEvery(0.01, function() ${probeName}.pids[hs.application.frontmostApplication():pid()] = true end)`);
  const browser = spawn(launcher, [
    `--user-data-dir=${profile}`, '--remote-debugging-pipe', '--no-first-run',
    '--no-default-browser-check', '--use-mock-keychain', 'about:blank',
  ], { stdio: ['ignore', 'ignore', 'inherit', 'pipe', 'pipe'] });
  const exited = once(browser, 'exit');
  const pending = new Map();
  let nextID = 0;
  const request = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++nextID;
    pending.set(id, { resolve, reject });
    browser.stdio[3].write(JSON.stringify({ id, method, params }) + '\0');
  });
  const reading = (async () => {
    for await (const reply of messages(browser.stdio[4])) {
      const waiter = pending.get(reply.id);
      if (!waiter) continue;
      pending.delete(reply.id);
      if (reply.error) waiter.reject(new Error(reply.error.message));
      else waiter.resolve(reply.result);
    }
  })();
  let chromePID;
  try {
    const info = await request('SystemInfo.getProcessInfo');
    chromePID = info.processInfo.find(item => item.type === 'browser').id;
    const target = await request('Target.createTarget', { url: 'about:blank', background: false, newWindow: true });
    await request('Target.activateTarget', { targetId: target.targetId });
    await pause(1200);
    const state = JSON.parse(hs(`local l=assert(agentBrowser.launches[${chromePID}]); local windows={}; for id, p in pairs(l.windows) do windows[#windows+1]={phase=p.phase,spaces=hs.spaces.windowSpaces(id)} end; return hs.json.encode({focused=${probeName}.pids[${chromePID}] == true, space=l.space, windows=windows})`));
    assert.equal(state.focused, false, 'Agent requests must not activate Chrome');
    assert(state.windows.length >= 2, `Both initial and additional windows must be tracked: ${JSON.stringify(state)}`);
    for (const window of state.windows) {
      assert.equal(window.phase, 'ready', JSON.stringify(state));
      assert.deepEqual(window.spaces, [state.space]);
    }
    if (mode === 'Browser.close') browser.stdio[3].write(JSON.stringify({ id: ++nextID, method: mode }) + '\0');
    else if (mode === 'SIGTERM') browser.kill('SIGTERM');
    else browser.stdio[3].end();
    let timeout;
    try {
      await Promise.race([exited, new Promise((_, reject) => {
        timeout = setTimeout(() => reject(new Error('Launcher did not stop')), 7000);
      })]);
    } finally {
      clearTimeout(timeout);
    }
    await reading;
    assert.throws(() => process.kill(chromePID, 0), { code: 'ESRCH' }, 'Chrome must also exit');
    console.log(`${mode}: windows stayed in the background on their desktop; launcher and Chrome stopped`);
  } finally {
    hs(`if ${probeName} then ${probeName}.timer:stop(); ${probeName}=nil end`);
    if (browser.exitCode === null && browser.signalCode === null) {
      browser.kill('SIGTERM');
      await exited;
    }
    rmSync(profile, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
  }
}
