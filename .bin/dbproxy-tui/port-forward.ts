import type { Subprocess } from "bun";
import type { DbTarget, Environment, AccessMode } from "./db-config.js";
import { getPort, getServiceName, getNamespace } from "./db-config.js";

export interface PortForwardProcess {
  target: DbTarget;
  port: number;
  serviceName: string;
  process: Subprocess;
  status: "connecting" | "connected" | "error";
  error?: string;
}

export function startPortForwards(
  targets: DbTarget[],
  env: Environment,
  mode: AccessMode
): PortForwardProcess[] {
  const ns = getNamespace(env, mode);
  const processes: PortForwardProcess[] = [];

  for (const target of targets) {
    const port = getPort(target, mode);
    const serviceName = getServiceName(target, mode);

    const proc = Bun.spawn(
      ["kubectl", "port-forward", `svc/${serviceName}`, "-n", ns, `${port}:${port}`],
      {
        stdout: "pipe",
        stderr: "pipe",
      }
    );

    const pf: PortForwardProcess = {
      target,
      port,
      serviceName,
      process: proc,
      status: "connecting",
    };

    // Monitor stderr for errors
    (async () => {
      const reader = proc.stderr.getReader();
      const decoder = new TextDecoder();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          const text = decoder.decode(value);
          if (text.includes("error") || text.includes("Error")) {
            pf.status = "error";
            pf.error = text.trim();
          }
        }
      } catch {
        // process ended
      }
    })();

    // Monitor stdout for connection success
    (async () => {
      const reader = proc.stdout.getReader();
      const decoder = new TextDecoder();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          const text = decoder.decode(value);
          if (text.includes("Forwarding")) {
            pf.status = "connected";
          }
        }
      } catch {
        // process ended
      }
    })();

    processes.push(pf);
  }

  return processes;
}

export function killAll(processes: PortForwardProcess[]) {
  for (const pf of processes) {
    try {
      pf.process.kill();
    } catch {
      // already exited
    }
  }
}

export function getStatusSummary(processes: PortForwardProcess[]): string {
  const lines: string[] = ["接続状況:"];
  const nameWidth = 30;
  const portWidth = 7;

  for (const pf of processes) {
    const icon =
      pf.status === "connected"
        ? "✓"
        : pf.status === "error"
          ? "✗"
          : "…";
    const statusColor =
      pf.status === "connected"
        ? "OK"
        : pf.status === "error"
          ? "NG"
          : "..";
    const name = pf.target.entry.name.padEnd(nameWidth);
    const port = String(pf.port).padStart(portWidth);
    const errMsg = pf.error ? ` ${pf.error}` : "";
    lines.push(`  [${statusColor}] ${icon} ${name} :${port}${errMsg}`);
  }

  return lines.join("\n");
}
