import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

const TIMESTAMP_ENTRY_TYPE = "message-timestamp";

type TimestampEntry = {
	timestamp: number;
};

function formatTime(timestamp: number): string | undefined {
	if (!Number.isFinite(timestamp)) return undefined;

	const date = new Date(timestamp);
	if (Number.isNaN(date.getTime())) return undefined;

	const hours = String(date.getHours()).padStart(2, "0");
	const minutes = String(date.getMinutes()).padStart(2, "0");
	return `${hours}:${minutes}`;
}

export default function messageTimestamps(pi: ExtensionAPI) {
	pi.registerEntryRenderer<TimestampEntry>(TIMESTAMP_ENTRY_TYPE, (entry, _options, theme) => {
		const storedTimestamp = entry.data?.timestamp;
		const timestamp = typeof storedTimestamp === "number" && Number.isFinite(storedTimestamp)
			? storedTimestamp
			: Date.parse(entry.timestamp);
		const time = formatTime(timestamp);
		if (!time) return undefined;

		return new Text(theme.fg("dim", time), 1, 0);
	});

	pi.on("message_start", (event) => {
		if (event.message.role !== "user") return;

		const content = event.message.content;
		const text = typeof content === "string"
			? content
			: content.filter((part) => part.type === "text").map((part) => part.text).join("");
		if (!text) return;

		pi.appendEntry<TimestampEntry>(TIMESTAMP_ENTRY_TYPE, {
			timestamp: event.message.timestamp,
		});
	});
}
