import { readFile, mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import {
	getSupportedThinkingLevels,
	type Api,
	type Model,
	type ModelThinkingLevel,
} from "@earendil-works/pi-ai";
import {
	DynamicBorder,
	getAgentDir,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Container, Key, type SelectItem, SelectList, Text } from "@earendil-works/pi-tui";

/**
 * Pick a saved model + effort combination with `/model-with-effort` or Ctrl+Shift+M.
 *
 * Favourites are stored in ~/.pi/agent/model-with-effort.json. Use the Add
 * option in the picker to choose from the models scoped to the current session.
 */

type Effort = ModelThinkingLevel;

type Favourite = {
	provider: string;
	model: string;
	thinkingLevel: Effort;
};

type Config = {
	favourites: Favourite[];
};

const CONFIG_PATH = join(getAgentDir(), "model-with-effort.json");
const ADD_FAVOURITE = "__add_favourite__";
const REMOVE_FAVOURITE = "__remove_favourite__";
const THINKING_LEVELS: readonly Effort[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];

function isEffort(value: unknown): value is Effort {
	return typeof value === "string" && THINKING_LEVELS.includes(value as Effort);
}

function favouriteKey(favourite: Favourite): string {
	return `${favourite.provider}/${favourite.model}:${favourite.thinkingLevel}`;
}

function modelKey(model: Model<Api>): string {
	return `${model.provider}/${model.id}`;
}

function parseFavourite(value: unknown): Favourite | undefined {
	if (!value || typeof value !== "object") return undefined;

	const record = value as Record<string, unknown>;
	const thinkingLevel = record.thinkingLevel ?? record.effort;
	if (
		typeof record.provider !== "string" ||
		typeof record.model !== "string" ||
		!isEffort(thinkingLevel)
	) {
		return undefined;
	}

	return {
		provider: record.provider,
		model: record.model,
		thinkingLevel,
	};
}

function normalizeFavourites(values: unknown): Favourite[] {
	if (!Array.isArray(values)) return [];

	const seen = new Set<string>();
	const favourites: Favourite[] = [];
	for (const value of values) {
		const favourite = parseFavourite(value);
		if (!favourite) continue;

		const key = favouriteKey(favourite);
		if (seen.has(key)) continue;
		seen.add(key);
		favourites.push(favourite);
	}
	return favourites;
}

async function loadFavourites(): Promise<Favourite[]> {
	try {
		const content = await readFile(CONFIG_PATH, "utf8");
		const parsed = JSON.parse(content) as { favourites?: unknown };
		return normalizeFavourites(parsed.favourites);
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
			console.error(`Failed to load ${CONFIG_PATH}:`, error);
		}
		return [];
	}
}

async function saveFavourites(favourites: Favourite[]): Promise<void> {
	await mkdir(getAgentDir(), { recursive: true });
	const config: Config = { favourites };
	await writeFile(CONFIG_PATH, `${JSON.stringify(config, null, 2)}\n`, "utf8");
}

function scopedModels(ctx: ExtensionContext): readonly { model: Model<Api> }[] {
	// `scopedModels` was added to the extension context after the first version
	// of this extension. Keep the fallback for sessions running an older Pi.
	return Array.isArray(ctx.scopedModels) ? ctx.scopedModels : [];
}

function currentModels(ctx: ExtensionContext): Model<Api>[] {
	const scoped = scopedModels(ctx);
	const models = scoped.length > 0
		? scoped.map(({ model }) => model)
		: (ctx.modelRegistry.getAvailable() ?? []);

	const seen = new Set<string>();
	return models.filter((model) => {
		const key = modelKey(model);
		if (seen.has(key)) return false;
		seen.add(key);
		return true;
	});
}

function findModel(models: readonly Model<Api>[], favourite: Favourite): Model<Api> | undefined {
	return models.find((model) => model.provider === favourite.provider && model.id === favourite.model);
}

function isActiveFavourite(ctx: ExtensionContext, favourite: Favourite): boolean {
	return (
		ctx.model?.provider === favourite.provider &&
		ctx.model.id === favourite.model &&
		(ctx.thinkingLevel ?? "off") === favourite.thinkingLevel
	);
}

async function selectItem(
	ctx: ExtensionContext,
	title: string,
	items: SelectItem[],
	hint: string,
): Promise<string | null> {
	const safeItems = items ?? [];
	if (safeItems.length === 0) return null;

	const result = await ctx.ui.custom<string | null>((tui, theme, _keybindings, done) => {
		const container = new Container();
		container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));
		container.addChild(new Text(theme.fg("accent", theme.bold(title)), 1, 0));

		const selectList = new SelectList(safeItems, Math.min(safeItems.length, 12), {
			selectedPrefix: (text) => theme.fg("accent", text),
			selectedText: (text) => theme.fg("accent", text),
			description: (text) => theme.fg("muted", text),
			scrollInfo: (text) => theme.fg("dim", text),
			noMatch: (text) => theme.fg("warning", text),
		});
		selectList.onSelect = (item) => done(item.value);
		selectList.onCancel = () => done(null);
		container.addChild(selectList);
		container.addChild(new Text(theme.fg("dim", hint), 1, 0));
		container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));

		return {
			render: (width: number) => container.render(width),
			invalidate: () => container.invalidate(),
			handleInput: (data: string) => {
				selectList.handleInput(data);
				tui.requestRender();
			},
		};
	});

	return result ?? null;
}

async function chooseFavourite(
	ctx: ExtensionContext,
	favourites: readonly Favourite[],
	models: readonly Model<Api>[],
): Promise<string | null> {
	const items: SelectItem[] = favourites.map((favourite, index) => {
		const model = findModel(models, favourite);
		const active = isActiveFavourite(ctx, favourite);
		const modelLabel = model?.id ?? favourite.model;
		const label = `${active ? "● " : "  "}${modelLabel} · ${favourite.thinkingLevel}`;
		const details = model
			? `${model.provider}${model.name !== model.id ? ` · ${model.name}` : ""}`
			: `${favourite.provider} · not in the current model scope`;
		return { value: `favourite:${index}`, label, description: details };
	});

	if (favourites.length > 0) {
		items.push({
			value: REMOVE_FAVOURITE,
			label: "− Remove a favourite",
			description: "Remove a saved model + effort combination",
		});
	}
	items.push({
		value: ADD_FAVOURITE,
		label: "+ Add model + effort",
		description: scopedModels(ctx).length > 0
			? "Choose from the models in the current scope"
			: "Choose from all available models",
	});

	return selectItem(ctx, "Model with effort", items, "↑↓ navigate • enter select • esc cancel");
}

async function addFavourite(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	models: readonly Model<Api>[],
): Promise<void> {
	const availableModels = models ?? [];
	if (availableModels.length === 0) {
		ctx.ui.notify(
			scopedModels(ctx).length > 0
				? "No models are available in the current scope. Update /scoped-models first."
				: "No available models found.",
			"warning",
		);
		return;
	}

	const modelItems: SelectItem[] = availableModels.map((model) => ({
		value: modelKey(model),
		label: model.id,
		description: `${model.provider}${model.name !== model.id ? ` · ${model.name}` : ""}`,
	}));
	const modelChoice = await selectItem(ctx, "Add model with effort", modelItems, "↑↓ navigate • enter select • esc cancel");
	if (!modelChoice) return;

	const model = availableModels.find((candidate) => modelKey(candidate) === modelChoice);
	if (!model) return;

	const levels = getSupportedThinkingLevels(model) ?? (model.reasoning ? THINKING_LEVELS : ["off"]);
	const effortItems: SelectItem[] = levels.map((level) => ({
		value: level,
		label: level,
		description: level === "off" ? "No reasoning" : "Reasoning effort",
	}));
	const effortChoice = await selectItem(
		ctx,
		`Choose effort for ${model.id}`,
		effortItems,
		"↑↓ navigate • enter select • esc cancel",
	);
	if (!effortChoice || !isEffort(effortChoice)) return;

	const favourite: Favourite = {
		provider: model.provider,
		model: model.id,
		thinkingLevel: effortChoice,
	};
	const favourites = await loadFavourites();
	if (!favourites.some((candidate) => favouriteKey(candidate) === favouriteKey(favourite))) {
		favourites.push(favourite);
		try {
			await saveFavourites(favourites);
		} catch (error) {
			ctx.ui.notify(`Could not save favourite: ${error instanceof Error ? error.message : String(error)}`, "error");
			return;
		}
	}

	await applyFavourite(pi, ctx, favourite, models);
}

async function removeFavourite(ctx: ExtensionContext): Promise<void> {
	const favourites = await loadFavourites();
	if (favourites.length === 0) return;

	const items: SelectItem[] = favourites.map((favourite, index) => ({
		value: `favourite:${index}`,
		label: `${favourite.model} · ${favourite.thinkingLevel}`,
		description: favourite.provider,
	}));
	const choice = await selectItem(ctx, "Remove favourite", items, "↑↓ navigate • enter remove • esc cancel");
	if (!choice?.startsWith("favourite:")) return;

	const index = Number(choice.slice("favourite:".length));
	if (!Number.isInteger(index) || index < 0 || index >= favourites.length) return;

	const [removed] = favourites.splice(index, 1);
	try {
		await saveFavourites(favourites);
	} catch (error) {
		ctx.ui.notify(`Could not save favourites: ${error instanceof Error ? error.message : String(error)}`, "error");
		return;
	}
	ctx.ui.notify(`Removed ${removed?.model ?? "favourite"} · ${removed?.thinkingLevel ?? ""}`.trim(), "info");
}

async function applyFavourite(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	favourite: Favourite,
	models: readonly Model<Api>[],
): Promise<boolean> {
	const model = findModel(models, favourite);
	if (!model) {
		ctx.ui.notify(
			`${favourite.provider}/${favourite.model} is not in the current model scope. Update /scoped-models or remove this favourite.`,
			"warning",
		);
		return false;
	}

	const alreadySelected = ctx.model?.provider === model.provider && ctx.model.id === model.id;
	if (!alreadySelected && !(await pi.setModel(model))) {
		ctx.ui.notify(`No API key is available for ${model.provider}/${model.id}`, "error");
		return false;
	}

	pi.setThinkingLevel(favourite.thinkingLevel);
	const effectiveLevel = pi.getThinkingLevel();
	if (effectiveLevel !== favourite.thinkingLevel) {
		ctx.ui.notify(
			`${model.id} does not support ${favourite.thinkingLevel}; using ${effectiveLevel} instead`,
			"warning",
		);
		return false;
	}

	ctx.ui.notify(`Model with effort: ${model.id} · ${effectiveLevel}`, "info");
	return true;
}

export default function modelWithEffort(pi: ExtensionAPI) {
	async function openPicker(ctx: ExtensionContext): Promise<void> {
		if (ctx.mode !== "tui") return;

		const favourites = await loadFavourites();
		const models = currentModels(ctx);
		const choice = await chooseFavourite(ctx, favourites, models);
		if (!choice) return;

		if (choice === ADD_FAVOURITE) {
			await addFavourite(pi, ctx, models);
			return;
		}
		if (choice === REMOVE_FAVOURITE) {
			await removeFavourite(ctx);
			return;
		}

		const index = Number(choice.slice("favourite:".length));
		const favourite = favourites[index];
		if (favourite) await applyFavourite(pi, ctx, favourite, models);
	}

	pi.registerShortcut(Key.ctrl("e"), {
		description: "Select model and effort",
		handler: openPicker,
	});

	pi.registerCommand("model-with-effort", {
		description: "Select a saved model and reasoning effort",
		handler: async (args, ctx) => {
			if (ctx.mode !== "tui") return;

			switch (args.trim().toLowerCase()) {
				case "":
					await openPicker(ctx);
					return;
				case "add":
					await addFavourite(pi, ctx, currentModels(ctx));
					return;
				case "remove":
					await removeFavourite(ctx);
					return;
				default:
					ctx.ui.notify("Usage: /model-with-effort [add|remove]", "warning");
			}
		},
	});
}
