#!/bin/sh

stow $(\ls conf) -R -t ~ -d conf --ignore="md|org"
