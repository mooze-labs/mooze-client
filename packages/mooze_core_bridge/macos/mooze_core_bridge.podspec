Pod::Spec.new do |s|
  s.name             = 'mooze_core_bridge'
  s.version          = '0.1.0'
  s.summary          = 'flutter_rust_bridge plugin for mooze-core.'
  s.description      = 'Builds the mooze-core Rust library with cargokit and links it.'
  s.homepage         = 'https://github.com/mooze-labs/mooze-client'
  s.license          = { :type => 'GPL-3.0-only' }
  s.author           = { 'Mooze' => 'dev@mooze.app' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'

  s.script_phase = {
    :name => 'Build Rust library',
    # Arguments: path to the Rust crate, then the Rust library name.
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../rust mooze_core_bridge',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    # Tells Xcode that this step creates the library -force_load uses.
    :output_files => ["${BUILT_PRODUCTS_DIR}/libmooze_core_bridge.a"],
  }
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libmooze_core_bridge.a',
  }
end
