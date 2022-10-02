#include "sora_texture.h"

#include "../SoraBase.h"

@interface SoraRendererTexture : NSObject <FlutterTexture>

@property (nonatomic) std::function<CVPixelBufferRef ()> copyTexture;

- (instancetype)initWithFunc:(std::function<CVPixelBufferRef ()>)copyTexture;

@end

@implementation SoraRendererTexture

- (instancetype)initWithFunc:(std::function<CVPixelBufferRef ()>)copyTexture
{
    if (self = [super init]) {
        self.copyTexture = copyTexture;
    }
    return self;
}

- (CVPixelBufferRef)copyPixelBuffer
{
    return self.copyTexture();
}

- (void)onTextureUnregistered:(NSObject<FlutterTexture>*)texture
{
}

@end

namespace sora_flutter_sdk {

class SoraTextureImpl : public SoraTexture {
public:
  SoraTextureImpl(std::function<CVPixelBufferRef ()> copy_texture);
  FlutterTexture* GetFlutterTexture() const override;

private:
  SoraRendererTexture* texture_;
};

SoraTextureImpl::SoraTextureImpl(std::function<CVPixelBufferRef ()> copy_texture) {
  texture_ = [[SoraRendererTexture alloc] initWithFunc:copy_texture];
}

FlutterTexture* SoraTextureImpl::GetFlutterTexture() const {
  return (id)texture_;
}

std::shared_ptr<SoraTexture> SoraTexture::Create(std::function<CVPixelBufferRef ()> copy_texture) {
  return std::make_shared<SoraTextureImpl>(copy_texture);
}

}
