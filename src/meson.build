ambersonic_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
  'preferences.vala',
  'api.vala',
]

blueprints = custom_target('blueprints',
  input: files(
    'gtk/help-overlay.blp',
    'window.blp',
    'preferences.blp',
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
