#!/usr/bin/env nix
#!nix shell ns#uv ns#python3 --command uv run --script --no-python-downloads
# ruff: noqa: E265 # messes with !nix shebang above
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "rich",
#     "click",
#     "toolz"
# ]
# ///


"""A very simple parser for the `nixos-option` output. Prints less stuff by default.

Known issues:
    - Removes newlines from long descriptions
"""
import json
import re
import sys

import click
import toolz
from rich import print_json
from rich.pretty import pprint
from toolz import pipe
from toolz.curried import keyfilter


def to_dict(lines: list[str]) -> dict:
    """Naive parser of the output.

    1. If a line does not have spaces in front of it -- the line becomes a dictionary key
    2. All lines with spaces in front become value of the current key
    """
    acc = {}
    for line in lines:
        if re.match(r"^[\w ]+:$", line):
            current_key = pipe(
                line,
                # Clean up
                lambda it: it.strip(),
                lambda it: it.removesuffix(":"),
            )
            acc.update({current_key: ""})
        else:
            acc[current_key] += pipe(
                line,
                lambda it: it.strip(),
                lambda it: it.removesuffix('"'),
                lambda it: it.removeprefix('"'),
                # Add some spaces to the front of the lines
                lambda it: " " + it,
            )

    # Strip the surrounding spaces
    acc = toolz.valmap(lambda it: it.strip(), acc)

    return acc


@click.command()
@click.option("--json", is_flag=True, default=False)
@click.option("--full", is_flag=True, default=False)
def _main(json, full):
    default_columns = ("Value", "Default")

    if json:
        print_f = lambda it: print_json(data=it)
    else:
        print_f = pprint

    if full:
        filter_f = toolz.identity
    else:
        filter_f = keyfilter(lambda it: it in default_columns)

    pipe(sys.stdin.readlines(), to_dict, filter_f, print_f)


if __name__ == "__main__":
    _main()
