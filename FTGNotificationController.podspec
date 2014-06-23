Pod::Spec.new do |spec|
  spec.name         = 'FTGNotificationController'
  spec.version      = '1.0'
  spec.license      =  { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage     = 'https://github.com/onmyway133/FTGNotificationController'
  spec.authors      = { 'Khoa Pham' => 'onmyway133@gmail.com' }
  spec.summary      = 'Similar to KVOController, but for NSNotification .'
  spec.source       = { :git => 'https://github.com/onmyway133/FTGNotificationController.git', :tag => '1.0' }
  spec.source_files = 'FTGNotificationController/FTGNotificationController.{h,m}'
  spec.requires_arc = true
  spec.ios.deployment_target = '6.0'
  spec.osx.deployment_target = '10.7'
  spec.social_media_url   = "https://twitter.com/onmyway133"
end
