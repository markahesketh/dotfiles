import { readFile, readdir } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { DynamicBorder, type ExtensionAPI, type Theme } from "@earendil-works/pi-coding-agent";
import {
	Container,
	Input,
	Key,
	matchesKey,
	Text,
	truncateToWidth,
	type Focusable,
} from "@earendil-works/pi-tui";

type HistoryItem = {
	text: string;
	timestamp: number;
};

type HistoryChoice = {
	action: "edit" | "send";
	text: string;
};

async function findSessionFiles(directory: string): Promise<string[]> {
	let entries;
	try {
		entries = await readdir(directory, { withFileTypes: true });
	} catch {
		return [];
	}

	const files = await Promise.all(
		entries.map(async (entry) => {
			const path = join(directory, entry.name);
			if (entry.isDirectory()) return findSessionFiles(path);
			return entry.isFile() && entry.name.endsWith(".jsonl") ? [path] : [];
		}),
	);
	return files.flat();
}

function promptText(content: unknown): string | undefined {
	if (typeof content === "string") return content.trim() || undefined;
	if (!Array.isArray(content)) return undefined;

	const text = content
		.filter((part): part is { type: "text"; text: string } =>
			typeof part === "object" && part !== null &&
			(part as { type?: unknown }).type === "text" &&
			typeof (part as { text?: unknown }).text === "string",
		)
		.map((part) => part.text)
		.join("\n")
		.trim();
	return text || undefined;
}

async function loadHistory(): Promise<HistoryItem[]> {
	const sessionRoot = join(homedir(), ".pi", "agent", "sessions");
	const files = await findSessionFiles(sessionRoot);
	const prompts: HistoryItem[] = [];

	await Promise.all(files.map(async (file) => {
		let contents: string;
		try {
			contents = await readFile(file, "utf8");
		} catch {
			return;
		}

		for (const line of contents.split("\n")) {
			if (!line) continue;
			try {
				const entry = JSON.parse(line) as {
					type?: string;
					timestamp?: string;
					message?: { role?: string; content?: unknown; timestamp?: number };
				};
				if (entry.type !== "message" || entry.message?.role !== "user") continue;
				const text = promptText(entry.message.content);
				if (!text) continue;
				prompts.push({
					text,
					timestamp: entry.message.timestamp ?? (Date.parse(entry.timestamp ?? "") || 0),
				});
			} catch {
				// Ignore incomplete or corrupt session lines.
			}
		}
	}));

	prompts.sort((a, b) => b.timestamp - a.timestamp);
	const seen = new Set<string>();
	return prompts.filter(({ text }) => {
		if (seen.has(text)) return false;
		seen.add(text);
		return true;
	});
}

class HistorySearch extends Container implements Focusable {
	private readonly input = new Input();
	private query = "";
	private matches: HistoryItem[] = [];
	private selected = 0;
	private _focused = false;

	get focused(): boolean {
		return this._focused;
	}

	set focused(value: boolean) {
		this._focused = value;
		this.input.focused = value;
	}

	constructor(
		private readonly history: HistoryItem[],
		private readonly theme: Theme,
		initialQuery: string,
		private readonly done: (choice: HistoryChoice | null) => void,
		private readonly requestRender: () => void,
	) {
		super();
		this.input.setValue(initialQuery);
		this.query = initialQuery;
		this.updateMatches();
	}

	private updateMatches(): void {
		const terms = this.query.toLocaleLowerCase().split(/\s+/).filter(Boolean);
		this.matches = this.history.filter(({ text }) => {
			const candidate = text.toLocaleLowerCase();
			return terms.every((term) => candidate.includes(term));
		});
		this.selected = Math.min(this.selected, Math.max(0, this.matches.length - 1));
	}

	handleInput(data: string): void {
		if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c"))) {
			this.done(null);
			return;
		}
		if (matchesKey(data, Key.up)) {
			this.selected = Math.max(0, this.selected - 1);
		} else if (matchesKey(data, Key.down)) {
			this.selected = Math.min(this.matches.length - 1, this.selected + 1);
		} else if (matchesKey(data, Key.enter)) {
			const match = this.matches[this.selected];
			if (match) this.done({ action: "send", text: match.text });
			return;
		} else if (matchesKey(data, Key.tab)) {
			const match = this.matches[this.selected];
			if (match) this.done({ action: "edit", text: match.text });
			return;
		} else {
			this.input.handleInput(data);
			const nextQuery = this.input.getValue();
			if (nextQuery !== this.query) {
				this.query = nextQuery;
				this.selected = 0;
				this.updateMatches();
			}
		}
		this.requestRender();
	}

	override render(width: number): string[] {
		const lines = [
			...new DynamicBorder((text: string) => this.theme.fg("accent", text)).render(width),
			...new Text(this.theme.fg("accent", this.theme.bold("Prompt history")), 1, 0).render(width),
			...this.input.render(width),
		];

		if (this.matches.length === 0) {
			lines.push(this.theme.fg("warning", "  No matching prompts"));
		} else {
			const visible = this.matches.slice(Math.max(0, this.selected - 4), Math.max(0, this.selected - 4) + 8);
			const start = this.matches.indexOf(visible[0]!);
			for (const [offset, item] of visible.entries()) {
				const selected = start + offset === this.selected;
				const singleLine = item.text.replace(/\s+/g, " ");
				const line = truncateToWidth(`${selected ? "→" : " "} ${singleLine}`, width - 2, "…");
				lines.push(selected ? this.theme.bg("selectedBg", this.theme.fg("accent", line)) : line);
			}
			lines.push(this.theme.fg("dim", `  ${this.selected + 1}/${this.matches.length}`));
		}

		lines.push(this.theme.fg("dim", "  ↑↓ navigate • enter send • tab edit • esc cancel"));
		lines.push(...new DynamicBorder((text: string) => this.theme.fg("accent", text)).render(width));
		return lines;
	}
}

export default function promptHistory(pi: ExtensionAPI) {
	pi.registerShortcut("ctrl+r", {
		description: "Search prompt history",
		handler: async (ctx) => {
			if (ctx.mode !== "tui") return;
			const history = await loadHistory();
			if (history.length === 0) {
				ctx.ui.notify("No prompt history found", "info");
				return;
			}

			const choice = await ctx.ui.custom<HistoryChoice | null>((tui, theme, _keybindings, done) =>
				new HistorySearch(history, theme, ctx.ui.getEditorText(), done, () => tui.requestRender()),
			);
			if (!choice) return;

			if (choice.action === "edit") {
				ctx.ui.setEditorText(choice.text);
			} else {
				pi.sendUserMessage(choice.text, ctx.isIdle() ? undefined : { deliverAs: "followUp" });
			}
		},
	});
}
