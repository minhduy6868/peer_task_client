// Conditional export for WebP2PService
// This file exports the correct implementation based on platform

export 'web_p2p_service_stub.dart'
    if (dart.library.html) 'web_p2p_service_web.dart';
