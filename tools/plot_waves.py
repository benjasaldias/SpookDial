"""Dibuja la curva de olas de una noche (Plan 9.1): lo que guarda test/dump_waves.gd.

Uso, desde la carpeta del proyecto (necesita matplotlib, que está en /usr/bin/python3):
    ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/dump_waves.gd -- 3 1 /ruta/noche3.json [normal|hard]
    /usr/bin/python3 tools/plot_waves.py /ruta/noche3.json /ruta/noche3.png
"""
import json
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

COLORS = {"request": "#ffb347", "incident": "#7ee08a", "hand": "#c084fc", "video": "#40c2c9"}
NAMES = {"request": "Solicitud", "incident": "Accidente", "hand": "La Mano", "video": "Video"}


def main(source, target):
    data = json.load(open(source, encoding="utf-8"))
    end = data["night_seconds"]
    fig, (top, bottom) = plt.subplots(2, 1, figsize=(13, 6), sharex=True, gridspec_kw={"height_ratios": [3, 1.2]})
    fig.patch.set_facecolor("#14161c")
    for axis in (top, bottom):
        axis.set_facecolor("#1c1f27")
        axis.tick_params(colors="#c8ccd8")
        for spine in axis.spines.values():
            spine.set_color("#3a3f4c")
    # Las olas, en rojo suave, y la final más fuerte; el silencio del comienzo, en gris.
    starts = [wave[0] for wave in data["waves"]] + [end]
    calms = data["calms"]
    for index, (start, finale) in enumerate(data["waves"]):
        stop = next((calm for calm in calms if calm > start), starts[index + 1]) if not finale else end
        for axis in (top, bottom):
            axis.axvspan(start, stop, color="#ff4d5e", alpha=0.28 if finale else 0.14, lw=0)
    for axis in (top, bottom):
        axis.axvspan(0, data["waves"][0][0] if data["waves"] else end, color="#888888", alpha=0.08, lw=0)
    # Cada tarea, de su llegada a su fin, en su fila.
    rows = {"request": 0, "incident": 1, "hand": 2, "video": 3}
    lanes = {}
    for task in sorted(data["tasks"], key=lambda item: item["arrival"]):
        kind = task["kind"]
        base = rows[kind] * 4
        lane = 0
        while lanes.get((kind, lane), -1) > task["arrival"]:
            lane += 1
        lanes[(kind, lane)] = task["end"]
        y = base + lane
        top.plot([task["arrival"], task["end"]], [y, y], color=COLORS[kind], lw=5, solid_capstyle="butt")
        top.plot([task["deadline"]], [y], marker="|", color="#ffffff", ms=9, alpha=0.6)
    for time in data["interferences"]:
        top.axvline(time, color="#56637f", lw=1.2, ls="--")
    for time, creature in data["scares"]:
        top.plot([time], [15.5], marker="v" if creature else "o", ms=11 if creature else 7,
                 color="#ff4d5e" if creature else "#e0e0e0")
    top.set_yticks([1.5, 5.5, 9.5, 13.5])
    top.set_yticklabels([NAMES[kind] for kind in ("request", "incident", "hand", "video")], color="#c8ccd8")
    top.set_ylim(-1, 17)
    names = {"normal": "Normal", "hard": "Difícil"}
    difficulty = names.get(data.get("difficulty", ""), data.get("difficulty", ""))
    title = "%s, noche %d (semilla %d): olas (rojo), calmas, la ola final (rojo fuerte) · batería que pide: %.0f %%" % (
        difficulty, data["night"], data["seed"], data["battery"])
    top.set_title(title, color="#e8eaf0", fontsize=11)
    bottom.step(range(len(data["load"])), data["load"], where="post", color="#ffb347", lw=1.6)
    bottom.set_ylabel("Tareas abiertas", color="#c8ccd8")
    ticks = [end * hour / 6 for hour in range(7)]
    bottom.set_xticks(ticks)
    bottom.set_xticklabels(["%02d:00\n%d s" % (hour, ticks[hour]) for hour in range(7)], color="#c8ccd8")
    bottom.set_xlim(0, end)
    legend = [plt.Line2D([0], [0], color="#56637f", ls="--", label="Interferencia"),
              plt.Line2D([0], [0], marker="o", color="#e0e0e0", lw=0, label="Screamer"),
              plt.Line2D([0], [0], marker="v", color="#ff4d5e", lw=0, ms=10, label="La criatura"),
              plt.Line2D([0], [0], marker="|", color="#ffffff", lw=0, ms=9, label="Plazo")]
    top.legend(handles=legend, loc="upper left", facecolor="#1c1f27", labelcolor="#e8eaf0", fontsize=8, ncol=4)
    plt.tight_layout()
    plt.savefig(target, dpi=90, facecolor=fig.get_facecolor())
    print("Curva guardada en", target)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
