project('com.gitlab.dusan-gvozdenovic.strings', 'vala', 'c')

i18n = import('i18n')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('APPLICATION_ID', meson.project_name())

configure_file(output: 'config.h', configuration: conf)
include_directories('.')

sources = files(
    'src/Config.vala',
    'src/Application.vala',
    'src/Audio.vala',
    'src/Gauge.vala',
    'src/Complex.vala'
)

deps = [
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    dependency('gtk+-3.0'),
    dependency('alsa'),
    meson.get_compiler('c').find_library('m', required: false),
]

app = executable(
    meson.project_name(),
    sources,
    c_args: [
        '-include', 'config.h',
        '-w'
    ],
    dependencies: deps,
    install: true
)

#Translate and install our .desktop file
i18n.merge_file(
    input: join_paths('data', meson.project_name() + '.desktop.in'),
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

subdir('po')