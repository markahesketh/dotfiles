import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const CONTEXT_LIMIT = 150_000;
const USAGE_REFRESH_INTERVAL_MS = 60_000;
const CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";
const CLAUDE_USAGE_URL = "https://api.anthropic.com/api/oauth/usage";
const SHORT_CACHE_TTL_MS = 5 * 60 * 1_000;
const LONG_CACHE_TTL_MS = 60 * 60 * 1_000;

type UsageWindow = {
	label: string;
	usedPercent: number;
	windowSeconds: number;
	resetsAt: number;
};

type CacheRefresh = {
	provider: string;
	model: string;
	timestamp: number;
};

function formatTokens(tokens: number): string {
	if (!Number.isFinite(tokens) || tokens <= 0) return "0";
	const thousands = tokens / 1_000;
	return `${thousands < 10 ? Number(thousands.toFixed(1)) : Math.round(thousands)}k`;
}

// Read the active session on every render so `/new` naturally starts at $0.
function sessionCost(ctx: ExtensionContext): number {
	let total = 0;

	for (const entry of ctx.sessionManager.getEntries()) {
		if (entry.type === "message") {
			if (entry.message.role === "assistant") {
				total += entry.message.usage.cost.total;
			} else if (entry.message.role === "toolResult" && entry.message.usage) {
				total += entry.message.usage.cost.total;
			}
		} else if ((entry.type === "compaction" || entry.type === "branch_summary") && entry.usage) {
			total += entry.usage.cost.total;
		}
	}

	return total;
}

function contextLabel(ctx: ExtensionContext): { label: string; overLimit: boolean } {
	const tokens = ctx.getContextUsage()?.tokens ?? 0;
	const percent = tokens > CONTEXT_LIMIT
		? Math.ceil((tokens / CONTEXT_LIMIT) * 100)
		: Math.floor((tokens / CONTEXT_LIMIT) * 100);
	return {
		label: `${formatTokens(tokens)} (${percent}%)`,
		overLimit: tokens > CONTEXT_LIMIT,
	};
}

function accountIdFromJwt(token: string): string | undefined {
	const payload = token.split(".")[1];
	if (!payload) return undefined;

	try {
		const decoded = Buffer.from(payload, "base64url").toString("utf8");
		const claims = JSON.parse(decoded) as {
			"https://api.openai.com/auth"?: { chatgpt_account_id?: unknown };
		};
		const accountId = claims["https://api.openai.com/auth"]?.chatgpt_account_id;
		return typeof accountId === "string" ? accountId : undefined;
	} catch {
		return undefined;
	}
}

function usageLabel(windowSeconds: number): string {
	if (windowSeconds <= 6 * 60 * 60) return "5h";
	if (windowSeconds >= 6 * 24 * 60 * 60) return "week";
	return `${Math.round(windowSeconds / 3_600)}h`;
}

function parseCodexWindow(value: unknown, nowMs: number): UsageWindow | undefined {
	if (!value || typeof value !== "object") return undefined;
	const record = value as Record<string, unknown>;
	const usedPercent = Number(record.used_percent);
	const windowSeconds = Number(record.limit_window_seconds);
	const resetAt = Number(record.reset_at) * 1_000 || nowMs + Number(record.reset_after_seconds) * 1_000;

	if (!Number.isFinite(usedPercent) || !Number.isFinite(windowSeconds) || !Number.isFinite(resetAt)) {
		return undefined;
	}

	return { label: usageLabel(windowSeconds), usedPercent, windowSeconds, resetsAt: resetAt };
}

async function fetchCodexUsage(ctx: ExtensionContext): Promise<UsageWindow[]> {
	const auth = await ctx.modelRegistry.getProviderAuth("openai-codex");
	const token = auth?.auth.apiKey;
	const accountId = token ? accountIdFromJwt(token) : undefined;
	if (!token || !accountId) return [];

	const response = await fetch(CODEX_USAGE_URL, {
		signal: AbortSignal.timeout(5_000),
		headers: {
			Authorization: `Bearer ${token}`,
			"chatgpt-account-id": accountId,
			originator: "pi",
		},
	});
	if (!response.ok) return [];

	const payload = (await response.json()) as {
		rate_limit?: { primary_window?: unknown; secondary_window?: unknown };
	};
	const nowMs = Date.now();
	return [
		parseCodexWindow(payload.rate_limit?.primary_window, nowMs),
		parseCodexWindow(payload.rate_limit?.secondary_window, nowMs),
	]
		.filter((window): window is UsageWindow => window !== undefined)
		.sort((a, b) => a.windowSeconds - b.windowSeconds);
}

function parseClaudeWindow(value: unknown, label: string, windowSeconds: number): UsageWindow | undefined {
	if (!value || typeof value !== "object") return undefined;
	const record = value as Record<string, unknown>;
	const utilization = Number(record.utilization);
	const usedPercent = utilization <= 1 ? utilization * 100 : utilization;
	const resetsAt = Date.parse(String(record.resets_at));
	if (!Number.isFinite(usedPercent) || !Number.isFinite(resetsAt)) return undefined;
	return { label, usedPercent, windowSeconds, resetsAt };
}

async function fetchClaudeUsage(ctx: ExtensionContext): Promise<UsageWindow[]> {
	const auth = await ctx.modelRegistry.getProviderAuth("anthropic");
	const token = auth?.auth.apiKey;
	if (!token) return [];

	const response = await fetch(CLAUDE_USAGE_URL, {
		signal: AbortSignal.timeout(5_000),
		headers: { Authorization: `Bearer ${token}`, "anthropic-beta": "oauth-2025-04-20" },
	});
	if (!response.ok) return [];

	const payload = (await response.json()) as { five_hour?: unknown; seven_day?: unknown };
	return [
		parseClaudeWindow(payload.five_hour, "5h", 5 * 60 * 60),
		parseClaudeWindow(payload.seven_day, "week", 7 * 24 * 60 * 60),
	].filter((window): window is UsageWindow => window !== undefined);
}

async function fetchSubscriptionUsage(ctx: ExtensionContext): Promise<UsageWindow[]> {
	switch (ctx.model?.provider) {
		case "openai-codex":
			return fetchCodexUsage(ctx);
		case "anthropic":
			return fetchClaudeUsage(ctx);
		default:
			return [];
	}
}

function usageWindowLabel(usageWindow: UsageWindow, nowMs = Date.now()): string {
	const remaining = Math.max(0, Math.min(100, Math.round(100 - usageWindow.usedPercent)));
	const resetInSeconds = Math.max(0, Math.round((usageWindow.resetsAt - nowMs) / 1_000));
	return `${usageWindow.label} ${remaining}% ↻ ${formatDuration(resetInSeconds)}`;
}

function formatDuration(totalSeconds: number): string {
	const days = Math.floor(totalSeconds / 86_400);
	const hours = Math.floor((totalSeconds % 86_400) / 3_600);
	const minutes = Math.ceil((totalSeconds % 3_600) / 60);
	if (days > 0) return `${days}d${hours > 0 ? ` ${hours}h` : ""}`;
	if (hours > 0) return `${hours}h${minutes > 0 ? ` ${minutes}m` : ""}`;
	return `${Math.max(1, minutes)}m`;
}

function usageColor(theme: Theme, window: UsageWindow, text: string): string {
	const remaining = 100 - window.usedPercent;
	if (remaining <= 20) return theme.fg("error", text);
	if (remaining <= 50) return theme.fg("warning", text);
	return theme.fg("success", text);
}

function cacheWarmthLabel(ctx: ExtensionContext, cacheRefresh: CacheRefresh | undefined): string | undefined {
	if (
		ctx.model?.provider !== "anthropic" ||
		!cacheRefresh ||
		cacheRefresh.provider !== ctx.model.provider ||
		cacheRefresh.model !== ctx.model.id
	) {
		return undefined;
	}

	const ttlMs = process.env.PI_CACHE_RETENTION === "long" ? LONG_CACHE_TTL_MS : SHORT_CACHE_TTL_MS;
	const remainingMs = cacheRefresh.timestamp + ttlMs - Date.now();
	return remainingMs > 0 ? ` cache ${formatDuration(Math.ceil(remainingMs / 1_000))}` : undefined;
}

function latestCacheRefresh(ctx: ExtensionContext): CacheRefresh | undefined {
	for (const entry of [...ctx.sessionManager.getBranch()].reverse()) {
		if (entry.type === "compaction") return undefined;
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;
		if (entry.message.stopReason === "error" || entry.message.stopReason === "aborted") continue;
		return { provider: entry.message.provider, model: entry.message.model, timestamp: entry.message.timestamp };
	}
}

export default function (pi: ExtensionAPI) {
	let projectName = "";
	let cacheRefresh: CacheRefresh | undefined;
	let usageWindows: UsageWindow[] = [];
	let usageRefreshTimer: ReturnType<typeof setInterval> | undefined;
	let requestRender: (() => void) | undefined;

	const refreshUsage = async (ctx: ExtensionContext) => {
		try {
			usageWindows = await fetchSubscriptionUsage(ctx);
		} catch {
			// Keep the last successful snapshot: status rendering must never fail because usage is unavailable.
		}
		requestRender?.();
	};

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		const gitRoot = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd: ctx.cwd, timeout: 2_000 }).catch(() => undefined);
		projectName = (gitRoot?.stdout.trim().split("/").pop() || ctx.cwd.split("/").pop() || "project").trim();
		cacheRefresh = latestCacheRefresh(ctx);

		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
			requestRender = () => tui.requestRender();

			return {
				dispose: () => {
					unsubscribe();
					requestRender = undefined;
				},
				invalidate() {},
				render(width: number): string[] {
					const context = contextLabel(ctx);
					const contextText = context.overLimit
						? theme.fg("error", context.label)
						: theme.fg("text", context.label);
					const model = theme.fg("success", ctx.model?.id ?? "no model");
					const thinkingLevel = theme.fg("accent", ` (${ctx.thinkingLevel})`);
					const cost = theme.fg("dim", ` $${sessionCost(ctx).toFixed(3)}`);
					const cacheWarmth = cacheWarmthLabel(ctx, cacheRefresh);
					const cache = cacheWarmth ? theme.fg("thinkingText", cacheWarmth) : "";
					const left = `${contextText}${theme.fg("dim", " • ")}${model}${thinkingLevel}${cost}${cache}`;
					const usage = usageWindows
						.map((window) => usageColor(theme, window, usageWindowLabel(window)))
						.join(theme.fg("dim", " • "));
					const usageGap = usage ? " ".repeat(Math.max(1, width - 1 - visibleWidth(left) - visibleWidth(usage))) : "";
					const topLine = truncateToWidth(` ${left}${usageGap}${usage}`, width);

					const branch = footerData.getGitBranch();
					const project = theme.fg("accent", projectName);
					const branchLabel = branch ? ` ${theme.fg("dim", "on")} ${theme.fg("error", branch)}` : "";
					const bottomLine = truncateToWidth(` ${project}${branchLabel}`, width);

					return [topLine, bottomLine];
				},
			};
		});

		void refreshUsage(ctx);
		usageRefreshTimer = setInterval(() => void refreshUsage(ctx), USAGE_REFRESH_INTERVAL_MS);
	});

	pi.on("message_end", (event) => {
		if (event.message.role !== "assistant") return;
		if (event.message.stopReason === "error" || event.message.stopReason === "aborted") return;
		cacheRefresh = {
			provider: event.message.provider,
			model: event.message.model,
			timestamp: event.message.timestamp,
		};
		requestRender?.();
	});

	pi.on("agent_settled", async (_event, ctx) => {
		void refreshUsage(ctx);
	});

	pi.on("model_select", async (_event, ctx) => {
		void refreshUsage(ctx);
	});

	pi.on("thinking_level_select", () => {
		requestRender?.();
	});

	pi.on("session_shutdown", () => {
		if (usageRefreshTimer) clearInterval(usageRefreshTimer);
		usageRefreshTimer = undefined;
		requestRender = undefined;
	});
}
