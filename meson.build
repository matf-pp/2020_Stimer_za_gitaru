project('com.gitlab.dusan-gvozdenovic.strings', 'vala', 'c')

i18n = import('i18n')
gnome = import('gnome')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('APPLICATION_ID', meson.project_name())

configure_file(output: 'config.h', configuration: conf)
include_directories('.')

sources = files(
    'src/Config.vala',
    'src/Application.vala',
    'src/Audio.vala',
    'src/Alsa.vala',
    'src/Gauge.vala',
    'src/Complex.vala',
    'src/ToneDisplay.vala',
    'src/PrefPane.vala',
    'src/AudioThread.vala',
    'src/Tuning.vala'
)

deps = [
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    dependency('gtk+-3.0'),
    dependency('alsa'),
    meson.get_compiler('c').find_library('m', required: false),
]

asresources = gnome.compile_resources(
    'as-resources',
    join_paths('data', meson.project_name()) + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

app = executable(
    meson.project_name(),
    sources,
    asresources,
    c_args: [
        '-include', 'config.h',
        '-w'
    ],
    dependencies: deps,
    install: true
)

#Translate and install .desktop file
i18n.merge_file(
    input: join_paths('data', meson.project_name() + '.desktop.in'),
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

# Install appdata.xml file
i18n.merge_file(
    input: join_paths('data', meson.project_name() + '.appdata.xml.in'),
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

subdir('po')
