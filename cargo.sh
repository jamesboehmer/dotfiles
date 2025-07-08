#!/bin/bash

for pkg in toml-cli; do
  cargo install $pkg;
done

