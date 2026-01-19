#!/bin/bash
# Build script for Warband Cultures Mod (macOS)
# Uses Python 2.7 via pyenv

PYTHON2=~/.pyenv/versions/2.7.18/bin/python

echo "Building Warband Cultures Mod..."
echo "Using Python: $PYTHON2"
echo ""

$PYTHON2 process_init.py
$PYTHON2 process_global_variables.py
$PYTHON2 process_strings.py
$PYTHON2 process_skills.py
$PYTHON2 process_music.py
$PYTHON2 process_animations.py
$PYTHON2 process_meshes.py
$PYTHON2 process_sounds.py
$PYTHON2 process_skins.py
$PYTHON2 process_map_icons.py
$PYTHON2 process_factions.py
$PYTHON2 process_items.py
$PYTHON2 process_scenes.py
$PYTHON2 process_troops.py
$PYTHON2 process_particle_sys.py
$PYTHON2 process_scene_props.py
$PYTHON2 process_tableau_materials.py
$PYTHON2 process_presentations.py
$PYTHON2 process_party_tmps.py
$PYTHON2 process_parties.py
$PYTHON2 process_quests.py
$PYTHON2 process_info_pages.py
$PYTHON2 process_scripts.py
$PYTHON2 process_mission_tmps.py
$PYTHON2 process_game_menus.py
$PYTHON2 process_simple_triggers.py
$PYTHON2 process_dialogs.py
$PYTHON2 process_global_variables_unused.py
$PYTHON2 process_postfx.py

rm -f *.pyc

echo ""
echo "____________________________"
echo ""
echo "Script processing has ended."
