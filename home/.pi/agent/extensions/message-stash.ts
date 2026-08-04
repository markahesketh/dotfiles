import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "message-stash";
const STATUS_TEXT = "draft stashed";

function hasDraft(text: string): boolean {
	return text.trim().length > 0;
}

function updateStatus(ctx: ExtensionContext, stashed: boolean): void {
	ctx.ui.setStatus(STATUS_KEY, stashed ? STATUS_TEXT : undefined);
}

export default function messageStash(pi: ExtensionAPI) {
	let stashedMessage: string | undefined;

	pi.registerShortcut("ctrl+s", {
		description: "Stash or restore the current message",
		handler: (ctx) => {
			if (ctx.mode !== "tui") return;

			const editorText = ctx.ui.getEditorText();
			if (stashedMessage === undefined) {
				if (!hasDraft(editorText)) return;

				stashedMessage = editorText;
				ctx.ui.setEditorText("");
				updateStatus(ctx, true);
				return;
			}

			if (hasDraft(editorText)) {
				stashedMessage = editorText;
				ctx.ui.setEditorText("");
				return;
			}

			ctx.ui.setEditorText(stashedMessage);
			stashedMessage = undefined;
			updateStatus(ctx, false);
		},
	});

	pi.on("input", (event, ctx) => {
		if (event.source !== "interactive" || stashedMessage === undefined) {
			return;
		}

		ctx.ui.setEditorText(stashedMessage);
		stashedMessage = undefined;
		updateStatus(ctx, false);
	});

	pi.on("session_shutdown", (_event, ctx) => {
		stashedMessage = undefined;
		updateStatus(ctx, false);
	});
}
