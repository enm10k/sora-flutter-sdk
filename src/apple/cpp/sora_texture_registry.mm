#include "sora_texture_registry.h"

#include "../SoraBase.h"

namespace sora_flutter_sdk {

class SoraTextureRegistryImpl : public SoraTextureRegistry {
public:
  SoraTextureRegistryImpl(FlutterTextureRegistry* registrar);
  int64_t RegisterTexture(FlutterTexture* texture) override;
  void UnregisterTexture(int64_t texture_id) override;
  void MarkTextureFrameAvailable(int64_t texture_id) override;

private:
  id<FlutterTextureRegistry> registrar_;
};

SoraTextureRegistryImpl::SoraTextureRegistryImpl(FlutterTextureRegistry* registrar) : registrar_((id)registrar) {
}

int64_t SoraTextureRegistryImpl::RegisterTexture(FlutterTexture* texture) {
  return [registrar_ registerTexture:(id)texture];
}
void SoraTextureRegistryImpl::UnregisterTexture(int64_t texture_id) {
  [registrar_ unregisterTexture:texture_id];
}
void SoraTextureRegistryImpl::MarkTextureFrameAvailable(int64_t texture_id) {
  [registrar_ textureFrameAvailable:texture_id];
}

std::shared_ptr<SoraTextureRegistry> SoraTextureRegistry::Create(void* registrar) {
  return std::make_shared<SoraTextureRegistryImpl>((__bridge FlutterTextureRegistry*)registrar);
}

}
