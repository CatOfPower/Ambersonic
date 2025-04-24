ambersonic_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
  'preferences.vala',
  'api.vala',
  'widgets/album_card.vala',
  'widgets/song_card.vala',
  'views/album_view.vala',
  'audio_player.vala',
  'player_manager.vala'
]

blueprints = custom_target('blueprints',
  input: files(
    'gtk/help-overlay.blp',
    'blueprints/window.blp',
    'blueprints/preferences.blp',
    'blueprints/album_view.blp'
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

ambersonic_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('libsoup-3.0'),
  dependency('libxml-2.0'),
  libm_dep,
  dependency('libcanberra'),
]

ambersonic_sources += gnome.compile_resources('ambersonic-resources',
  'ambersonic.gresource.xml',
  c_name: 'ambersonic',
  dependencies: [blueprints],
)

executable('ambersonic', ambersonic_sources,
  dependencies: ambersonic_deps,
  include_directories: config_inc,
  install: true,
)
