import os
import shutil
import sys
from pathlib import Path

from xonsh.built_ins import XSH

__all__ = ()


def _setup() -> None:
    """Configure starship prompt when running inside xonsh."""
    env = getattr(XSH, "env", None)
    if env is None:
        return

    if shutil.which("starship") is None:
        print("xontrib-prompt-starship: warning - starship binary not found", file=sys.stderr)
        return

    env["STARSHIP_SHELL"] = "xonsh"
    try:
        env["STARSHIP_SESSION_KEY"] = XSH.subproc_captured_stdout(["starship", "session"]).strip()
    except Exception:
        pass

    def _starship_prompt(cfg: str) -> str:
        with env.swap({"STARSHIP_CONFIG": cfg} if cfg else {}):
            return XSH.subproc_captured_stdout([
                "starship",
                "prompt",
                ("--status=" + (str(int(XSH.history[-1].rtn)) if len(XSH.history) > 0 else "0")),
                "--cmd-duration",
                str(int((XSH.history[-1].ts[1] - XSH.history[-1].ts[0]) * 1000)) if len(XSH.history) > 0 else "0",
                "--jobs",
                str(len(XSH.all_jobs)),
                "--terminal-width",
                str(os.get_terminal_size().columns),
            ])

    replace_prompt = env.get("XONTRIB_PROMPT_STARSHIP_REPLACE_PROMPT", True)

    left_cfg = env.get("XONTRIB_PROMPT_STARSHIP_LEFT_CONFIG", env.get("STARSHIP_CONFIG", ""))
    if left_cfg:
        left_cfg_path = Path(left_cfg).expanduser()
        if left_cfg_path.exists():
            left_cfg = str(left_cfg_path)
        else:
            print(f"xontrib-prompt-starship: The path doesn't exist: {left_cfg_path}", file=sys.stderr)
            left_cfg = ""
    env["PROMPT_FIELDS"]["starship_left"] = lambda: _starship_prompt(left_cfg)
    if replace_prompt:
        env["PROMPT"] = "{starship_left}"

    right_cfg = env.get("XONTRIB_PROMPT_STARSHIP_RIGHT_CONFIG", "")
    if right_cfg:
        right_cfg_path = Path(right_cfg).expanduser()
        if right_cfg_path.exists():
            env["PROMPT_FIELDS"]["starship_right"] = lambda: _starship_prompt(str(right_cfg_path))
            if replace_prompt:
                env["RIGHT_PROMPT"] = "{starship_right}"
        else:
            print(f"xontrib-prompt-starship: The path doesn't exist: {right_cfg_path}", file=sys.stderr)

    bottom_cfg = env.get("XONTRIB_PROMPT_STARSHIP_BOTTOM_CONFIG", "")
    if bottom_cfg:
        bottom_cfg_path = Path(bottom_cfg).expanduser()
        if bottom_cfg_path.exists():
            env["PROMPT_FIELDS"]["starship_bottom_toolbar"] = lambda: _starship_prompt(str(bottom_cfg_path))
            if replace_prompt:
                env["BOTTOM_TOOLBAR"] = "{starship_bottom_toolbar}"
        else:
            print(f"xontrib-prompt-starship: The path doesn't exist: {bottom_cfg_path}", file=sys.stderr)


_setup()
