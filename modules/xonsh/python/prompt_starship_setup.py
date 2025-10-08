from setuptools import setup

setup(
    name="xontrib-prompt-starship",
    version="0.3.6",
    description="Starship prompt integration for xonsh (with nix guard)",
    packages=["xontrib"],
    package_dir={"xontrib": "xontrib"},
    license="MIT",
)
