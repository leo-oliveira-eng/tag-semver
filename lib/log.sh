#!/usr/bin/env bash

info() {
  echo "::notice::$*"
}

warn() {
  echo "::warning::$*"
}

error() {
  echo "::error::$*" >&2
}
