import subprocess
from xonsh.built_ins import XSH

__all__ = ()


def _load_carapace() -> None:
    """Load carapace completions if the binary is available."""
    if XSH is None or XSH.env is None:
        # Module imported outside of a running xonsh session
        return

    carapace_cmd = XSH.env.get("CARAPACE_COMMAND", "carapace")

    try:
        result = subprocess.run(
            [carapace_cmd, "_carapace"],
            check=True,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except FileNotFoundError:
        print("xontrib-carapace-bin: warning - carapace executable not found")
        return
    except subprocess.CalledProcessError as exc:
        print(
            "xontrib-carapace-bin: warning - "
            f"carapace _carapace failed with exit code {exc.returncode}"
        )
        if exc.stderr:
            print(exc.stderr.strip())
        return

    XSH.builtins.execx(result.stdout, glbs=None, locs=None)


_load_carapace()
