import { spawn, execFileSync } from 'node:child_process';
import { accessSync, constants } from 'node:fs';
import { Socket } from 'node:net';
import { once } from 'node:events';
import { fileURLToPath } from 'node:url';

// Keep focus policy below the agent's per-call background/bringToFront choices.
export function backgroundCommand(command) {
  if (command.method === 'Page.bringToFront' || command.method === 'Target.activateTarget') {
    return { reply: { id: command.id, result: {}, ...(command.sessionId && { sessionId: command.sessionId }) } };
  }
  if (command.method === 'Target.createTarget') {
    return { forward: { ...command, params: { ...command.params, background: true } } };
  }
  return { forward: command };
}

export async function* messages(stream) {
  stream.setEncoding('utf8');
  let pending = '';
  for await (const chunk of stream) {
    pending += chunk;
    let end;
    while ((end = pending.indexOf('\0')) !== -1) {
      const frame = pending.slice(0, end);
      pending = pending.slice(end + 1);
      yield JSON.parse(frame);
    }
  }
  if (pending) throw new Error('Incomplete Chrome debugging message');
}

async function send(stream, message) {
  if (!stream.write(JSON.stringify(message) + '\0')) await once(stream, 'drain');
}

async function launch(args) {
  if (!args.includes('--remote-debugging-pipe')) {
    throw new Error('Headed agent-chrome requires --remote-debugging-pipe (Chrome DevTools MCP uses this).');
  }
  const hs = code => execFileSync('/opt/homebrew/bin/hs', ['-q', '-t', '5', '-c', code], {
    encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'],
  });
  const helper = fileURLToPath(new URL('../hammerspoon/.build/move-window-space', import.meta.url));
  try {
    accessSync(helper, constants.X_OK);
  } catch {
    throw new Error('Run python3 bin/setup-agent-chrome to build the desktop-move helper.');
  }
  hs("assert(agentBrowser and agentBrowser.backgroundLaunch, 'Run python3 bin/setup-agent-chrome and reload Hammerspoon')");

  // No startup window prevents macOS activation before a background target exists.
  const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
    ...args, '--no-startup-window',
  ], { stdio: ['inherit', 'inherit', 'inherit', 'pipe', 'pipe'] });
  const input = new Socket({ fd: 3, readable: true, writable: false });
  const output = new Socket({ fd: 4, readable: false, writable: true });
  const stop = () => chrome.kill('SIGTERM');
  process.on('SIGTERM', stop);
  process.on('SIGINT', stop);
  process.on('SIGHUP', stop);
  input.on('end', stop);
  chrome.on('exit', (code, signal) => process.exit(code ?? (signal ? 1 : 0)));
  chrome.on('error', error => { console.error(error.message); process.exit(1); });
  try {
    hs(`agentBrowser.prepare(${chrome.pid})`);
    const replies = messages(chrome.stdio[4]);
    await send(chrome.stdio[3], { id: -1, method: 'Target.createTarget', params: { url: 'about:blank', background: true } });
    // Finish our private startup request before forwarding the client's IDs.
    while (true) {
      const { value: reply, done } = await replies.next();
      if (done) throw new Error('Chrome closed before creating its first page');
      if (reply.id === -1) {
        if (reply.error) throw new Error(reply.error.message);
        break;
      }
      await send(output, reply);
    }
    hs(`agentBrowser.watch(${chrome.pid})`);
    await Promise.all([
      (async () => {
        for await (const command of messages(input)) {
          const result = backgroundCommand(command);
          await send(result.reply ? output : chrome.stdio[3], result.reply ?? result.forward);
        }
      })(),
      (async () => {
        for await (const reply of replies) await send(output, reply);
      })(),
    ]);
  } finally {
    stop();
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  launch(process.argv.slice(2)).catch(error => {
    console.error(`agent-chrome: ${error.message}`);
    process.exit(1);
  });
}
