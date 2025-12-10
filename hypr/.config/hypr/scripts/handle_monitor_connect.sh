#!/bin/bash

hyprctl dispatch workspace "1"
hyprctl dispatch workspace "2"
hyprctl dispatch workspace "3"
hyprctl dispatch workspace "4"
hyprctl dispatch workspace "5"
hyprctl dispatch workspace "6"

hyprctl dispatch moveworkspacetomonitor "1 1"
hyprctl dispatch moveworkspacetomonitor "2 1"
hyprctl dispatch moveworkspacetomonitor "3 1"
hyprctl dispatch moveworkspacetomonitor "4 1"
hyprctl dispatch moveworkspacetomonitor "5 1"
hyprctl dispatch moveworkspacetomonitor "6 0"
# hyprctl dispatch moveworkspacetomonitor "7 0"
# hyprctl dispatch moveworkspacetomonitor "8 0"
# hyprctl dispatch moveworkspacetomonitor "9 0"
# hyprctl dispatch moveworkspacetomonitor "10 0"
