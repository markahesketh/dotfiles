import net from "node:net";

const socketPath = process.env.HERDR_SOCKET_PATH;
const paneId = process.env.HERDR_ACTIVE_PANE_ID || process.env.HERDR_PANE_ID;

if (!socketPath) {
  throw new Error("HERDR_SOCKET_PATH is not set");
}

let requestId = 0;

function request(method, params = {}) {
  return new Promise((resolve, reject) => {
    const client = net.createConnection(socketPath);
    let buffer = "";
    let settled = false;

    const finish = (callback, value) => {
      if (settled) return;
      settled = true;
      callback(value);
    };

    client.setTimeout(5000, () => {
      client.destroy();
      finish(reject, new Error(`Herdr request timed out: ${method}`));
    });

    client.on("connect", () => {
      client.write(
        `${JSON.stringify({
          id: String(++requestId),
          method,
          params,
        })}\n`,
      );
    });

    client.on("data", (chunk) => {
      buffer += chunk.toString();
      const newline = buffer.indexOf("\n");
      if (newline < 0) return;

      const message = JSON.parse(buffer.slice(0, newline));
      client.end();

      if (message.error) {
        finish(reject, new Error(message.error.message || "Herdr request failed"));
      } else {
        finish(resolve, message.result);
      }
    });

    client.on("error", (error) => finish(reject, error));
    client.on("close", () => {
      if (!settled) finish(reject, new Error(`Herdr closed the request: ${method}`));
    });
  });
}

export function splitPaths(node, path = [], splits = []) {
  if (!node || node.type !== "split") return splits;

  splits.push({ path, ratio: node.ratio });
  splitPaths(node.first, [...path, false], splits);
  splitPaths(node.second, [...path, true], splits);
  return splits;
}

export async function equalizeInPlace(pane) {
  const { layout } = await request("layout.export", pane ? { pane_id: pane } : {});
  const splits = splitPaths(layout.root).filter(
    ({ ratio }) => Math.abs(ratio - 0.5) > 0.01,
  );

  for (const { path } of splits) {
    await request("layout.set_split_ratio", {
      tab_id: layout.tab_id,
      path,
      ratio: 0.5,
    });
  }

  return splits.length;
}

try {
  const changed = await equalizeInPlace(paneId);
  console.log(
    changed === 1
      ? "equalize: 1 split set to 50/50"
      : `equalize: ${changed} splits set to 50/50`,
  );
} catch (error) {
  console.error(`equalize: ${error.message}`);
  process.exitCode = 1;
}
