Pod::Spec.new do |s|

  s.name         = "SFPSDWriter"
  s.version      = "0.2.1"
  s.summary      = "A simple Objective C (Mac and iOS) writer for .psd files with multiple layers and groups."

  s.description  = <<-DESC
                   SFPSDWriter is an Objective-C library for writing PSD files. Here at Shiny Frog we needed a way to write **multilayer** **PSDs** with **groups** and this library is the result after days of headaches.

                   It features:

                   * Multilayer PSD creation
                   * Grouping of layers
                   * Unicode layer name support
                   * Some layer configurations (like the blend mode of the layer)
                   * ARC (Automatic Reference Counting)

                   What SFPSDWriter **NOT** features:

                   * Ability to read PSD files
                   DESC

  s.homepage     = "https://github.com/shinyfrog/SFPSDWriter/"

  s.license      = { :type => 'BSD' }

  s.author       = { "Shiny Frog" => "shinyfrog@shinyfrog.net" }

  s.source       = { :git => "https://github.com/shinyfrog/SFPSDWriter.git", :tag => s.version.to_s  }

  s.platform     = :ios, :osx

  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.8"

  s.source_files    = "Library/SFPSDWriter/**/*.{h,m}"

  s.requires_arc  = true


end
