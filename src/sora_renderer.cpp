#include "sora_renderer.h"

#include <rtc_base/logging.h>

#if defined(__ANDROID__)

#include <sdk/android/native_api/jni/class_loader.h>

#include <future>
#include <functional>


extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_RunOnMainThread_nativeRun(JNIEnv* env,
                                         jobject /* this */, jlong ptr) {
  (*reinterpret_cast<std::function<void ()>*>(ptr))();
}

template<class T>
T InvokeOnMainThread(JNIEnv* env, std::function<T (JNIEnv*)> f) {
  std::promise<T> promise;
  auto future = promise.get_future();
  std::function<void ()> wf = [&promise, &f]() {
    auto env = webrtc::AttachCurrentThreadIfNeeded();
    try {
      promise.set_value(f(env));
    } catch (...) {
      promise.set_exception(std::current_exception());
    }
  };

  // var r = new RunOnMainThread(&f);
  // r.run();
  auto cls = webrtc::GetClass(env, "jp/shiguredo/sora_flutter_sdk/RunOnMainThread");
  jmethodID init_id = env->GetMethodID(cls.obj(), "<init>", "(J)V");
  jmethodID run_id = env->GetMethodID(cls.obj(), "run", "()V");
  webrtc::ScopedJavaLocalRef<jobject> obj(env, env->NewObject(cls.obj(), init_id, reinterpret_cast<jlong>(&wf)));
  env->CallVoidMethod(obj.obj(), run_id);

  return future.get();
}

void RunOnMainThread(JNIEnv* env, std::function<void (JNIEnv*)> f) {
  std::promise<void> promise;
  auto future = promise.get_future();
  std::function<void ()> wf = [&promise, &f]() {
    auto env = webrtc::AttachCurrentThreadIfNeeded();
    try {
      f(env);
      promise.set_value();
    } catch (...) {
      promise.set_exception(std::current_exception());
    }
  };

  // var r = new RunOnMainThread(&f);
  // r.run();
  auto cls = webrtc::GetClass(env, "jp/shiguredo/sora_flutter_sdk/RunOnMainThread");
  jmethodID init_id = env->GetMethodID(cls.obj(), "<init>", "(J)V");
  jmethodID run_id = env->GetMethodID(cls.obj(), "run", "()V");
  webrtc::ScopedJavaLocalRef<jobject> obj(env, env->NewObject(cls.obj(), init_id, reinterpret_cast<jlong>(&wf)));
  env->CallVoidMethod(obj.obj(), run_id);

  return future.get();
}

#elif defined(__APPLE__)

@interface SoraRendererTexture : NSObject <FlutterTexture>

typedef CVPixelBufferRef (^SoraRendererCopyPixelBuffer)(void);

@property (nonatomic, copy) SoraRendererCopyPixelBuffer block;

- (instancetype)initWithBlock:(SoraRendererCopyPixelBuffer)block;

@end

@implementation SoraRendererTexture

- (instancetype)initWithBlock:(SoraRendererCopyPixelBuffer)block
{
    if (self = [super init]) {
        self.block = block;
    }
    return self;
}

- (CVPixelBufferRef)copyPixelBuffer
{
    return self.block();
}

- (void)onTextureUnregistered:(NSObject<FlutterTexture>*)texture
{
}

@end

#elif defined(__linux__)

typedef gboolean (*CopyPixelFunction)(void* data,
                                      FlPixelBufferTexture* texture,
                                      const uint8_t** buffer,
                                      uint32_t* width,
                                      uint32_t* height,
                                      GError** error);
struct PixelBuffer {
  FlPixelBufferTexture parent_instance;
  CopyPixelFunction copy_pixels;
  void* data;
};

struct PixelBufferClass {
  FlPixelBufferTextureClass parent_class;
};

G_DEFINE_TYPE(PixelBuffer, pixel_buffer, fl_pixel_buffer_texture_get_type())

#define PIXEL_BUFFER(obj) (G_TYPE_CHECK_INSTANCE_CAST((obj), pixel_buffer_get_type(), PixelBuffer))

static gboolean _pixel_buffer_copy_pixels(FlPixelBufferTexture* texture, const uint8_t** dst, uint32_t* width, uint32_t *height, GError** error) {
  PixelBuffer* buffer = PIXEL_BUFFER(texture);
  return buffer->copy_pixels(buffer->data, texture, dst, width, height, error);
}

static void _pixel_buffer_dispose(GObject* object) {
  // PixelBuffer* buffer = PIXEL_BUFFER(object);
  G_OBJECT_CLASS(pixel_buffer_parent_class)->dispose(object);
}

static void pixel_buffer_class_init(PixelBufferClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = _pixel_buffer_dispose;
  klass->parent_class.copy_pixels = _pixel_buffer_copy_pixels;
}

static void pixel_buffer_init(PixelBuffer* buffer) {
  buffer->data = nullptr;
  buffer->copy_pixels = nullptr;
}

PixelBuffer* pixel_buffer_new(CopyPixelFunction copy_pixels, void* data) {
  PixelBuffer* buffer = PIXEL_BUFFER(g_object_new(pixel_buffer_get_type(), nullptr));
  buffer->copy_pixels = copy_pixels;
  buffer->data = data;
  return buffer;
}

#endif

namespace sora_flutter_sdk {

// SoraRenderer::Sink

#if defined(__ANDROID__)
SoraRenderer::Sink::Sink(webrtc::VideoTrackInterface* track, JNIEnv* env, jobject texture_registrar)
#elif defined(_WIN32)
SoraRenderer::Sink::Sink(webrtc::VideoTrackInterface* track, flutter::TextureRegistrar* texture_registrar)
#elif defined(__APPLE__)
SoraRenderer::Sink::Sink(webrtc::VideoTrackInterface* track, id<FlutterTextureRegistry> texture_registrar)
#elif defined(__linux__)
SoraRenderer::Sink::Sink(webrtc::VideoTrackInterface* track, FlTextureRegistrar* texture_registrar)
#endif
    : track_(track)
#if defined(__ANDROID__)
    , texture_registrar_(env, webrtc::JavaParamRef<jobject>(texture_registrar))
    , env_(env)
#else
    , texture_registrar_(texture_registrar)
#endif
    {
  RTC_LOG(LS_INFO) << "[" << (void*)this << "] Sink::Sink";

#if defined(__ANDROID__)
  // texture_entry_ = texture_registrar.createSurfaceTexture();
  auto texture_entry = InvokeOnMainThread<jobject>(env, [texture_registrar](JNIEnv* env) {
    webrtc::ScopedJavaLocalRef<jclass> texcls(env, env->GetObjectClass(texture_registrar));
    jmethodID create_surface_id = env->GetMethodID(texcls.obj(), "createSurfaceTexture", "()Lio/flutter/view/TextureRegistry$SurfaceTextureEntry;");
    webrtc::ScopedJavaLocalRef<jobject> texture_entry(env, env->CallObjectMethod(texture_registrar, create_surface_id));
    return env->NewGlobalRef(texture_entry.obj());
  });
  texture_entry_ = webrtc::JavaParamRef<jobject>(env, texture_entry);
  RunOnMainThread(env, [texture_entry](JNIEnv* env) {
    env->DeleteGlobalRef(texture_entry);
  });

#elif defined(_WIN32)
  texture_ = std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
      [this](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
        // RTC_LOG(LS_INFO) << "[" << (void*)this << "] Sink::CopyTexture";
        std::lock_guard<std::mutex> guard(mutex_);
        if (frame_ == nullptr) {
          return nullptr;
        }

        if (pixel_buffer_ == nullptr) {
          pixel_buffer_.reset(new FlutterDesktopPixelBuffer());
          pixel_buffer_->width = 0;
          pixel_buffer_->height = 0;
        }

        if (pixel_buffer_->width != frame_->width() || pixel_buffer_->height != frame_->height()) {
          rgba_buffer_.reset(new uint8_t[frame_->width() * frame_->height() * 4]);
          pixel_buffer_->width = frame_->width();
          pixel_buffer_->height = frame_->height();
          pixel_buffer_->buffer = rgba_buffer_.get();
        }

        auto buf = frame_->video_frame_buffer()->ToI420();
        libyuv::I420ToABGR(
          buf->DataY(), buf->StrideY(),
          buf->DataU(), buf->StrideU(),
          buf->DataV(), buf->StrideV(),
          rgba_buffer_.get(), frame_->width() * 4,
          frame_->width(), frame_->height());

        return pixel_buffer_.get();
      }));
#elif defined(__APPLE__)
  texture_ = [[SoraRendererTexture alloc] initWithBlock:^{
    // RTC_LOG(LS_INFO) << "[" << (void *)this << "] Sink::CopyTexture";
    std::lock_guard<std::mutex> guard(mutex_);
    if (frame_ == nullptr)
    {
      return (CVPixelBufferRef)NULL;
    }

    int pitch = CVPixelBufferGetBytesPerRow(pixel_buffer_);

    if (pixel_buffer_ == NULL ||
        CVPixelBufferGetWidth(pixel_buffer_) != frame_->width() ||
        CVPixelBufferGetHeight(pixel_buffer_) != frame_->height())
    {
      if (pixel_buffer_ == NULL) {
        RTC_LOG(LS_INFO) << " Change PixelBuffer size 0x0 to "
          << frame_->width() << "x" << frame_->height();
      } else {
        RTC_LOG(LS_INFO) << " Change PixelBuffer size "
          << CVPixelBufferGetWidth(pixel_buffer_) << "x" << CVPixelBufferGetHeight(pixel_buffer_) << " to "
          << frame_->width() << "x" << frame_->height();
      }

      CVPixelBufferRelease(pixel_buffer_);

      NSDictionary *options = @{
        (NSString *)kCVPixelBufferMetalCompatibilityKey : @YES,
      };
      CVReturn status = CVPixelBufferCreate(NULL,
                                            frame_->width(), frame_->height(),
                                            kCVPixelFormatType_32ARGB,
                                            (__bridge CFDictionaryRef)options,
                                            &pixel_buffer_);
      if (status != kCVReturnSuccess)
      {
        return (CVPixelBufferRef)NULL;
      }

      pitch = CVPixelBufferGetBytesPerRow(pixel_buffer_);
    }

    auto buf = frame_->video_frame_buffer()->ToI420();

    CVReturn status = CVPixelBufferLockBaseAddress(pixel_buffer_, 0);
    if (status != kCVReturnSuccess)
    {
      return (CVPixelBufferRef)NULL;
    }

    uint8_t* p = (uint8_t*)CVPixelBufferGetBaseAddress(pixel_buffer_);
    libyuv::I420ToARGB(
        buf->DataY(), buf->StrideY(),
        buf->DataU(), buf->StrideU(),
        buf->DataV(), buf->StrideV(),
        p, pitch,
        frame_->width(), frame_->height());

    status = CVPixelBufferUnlockBaseAddress(pixel_buffer_, 0);
    if (status != kCVReturnSuccess)
    {
      return (CVPixelBufferRef)NULL;
    }

    CFRetain(pixel_buffer_);
    return pixel_buffer_;
  }];
#elif defined(__linux__)
  texture_.reset(FL_TEXTURE(pixel_buffer_new([](void* data,
                                      FlPixelBufferTexture* texture,
                                      const uint8_t** buffer,
                                      uint32_t* width,
                                      uint32_t* height,
                                      GError** error) -> gboolean {
    // RTC_LOG(LS_INFO) << "[" << data << "] Sink::CopyTexture";

    auto self = (SoraRenderer::Sink*)data;

    if (error != nullptr) {
      *error = nullptr;
    }

    std::lock_guard<std::mutex> guard(self->mutex_);
    if (self->frame_ == nullptr) {
      *error = g_error_new(g_quark_from_static_string("pixel_buffer"), 1, "frame is null");
      return FALSE;
    }

    if (self->rgba_buffer_ == nullptr ||
        self->width_ != self->frame_->width() ||
        self->height_ != self->frame_->height()) {
      self->rgba_buffer_.reset(new uint8_t[self->frame_->width() * self->frame_->height() * 4]);
      self->width_ = self->frame_->width();
      self->height_ = self->frame_->height();
    }

    *width = self->frame_->width();
    *height = self->frame_->height();
    *buffer = self->rgba_buffer_.get();

    auto buf = self->frame_->video_frame_buffer()->ToI420();
    libyuv::I420ToABGR(
      buf->DataY(), buf->StrideY(),
      buf->DataU(), buf->StrideU(),
      buf->DataV(), buf->StrideV(),
      self->rgba_buffer_.get(), self->frame_->width() * 4,
      self->frame_->width(), self->frame_->height());

    return TRUE;
  }, this)), [](FlTexture* p) {
    g_object_unref(p);
  });
#endif

#if defined(__ANDROID__)
  // texture_id_ = texture_entry_.id();
  webrtc::ScopedJavaLocalRef<jclass> entrycls(env, env->GetObjectClass(texture_entry_.obj()));
  jmethodID get_id = env->GetMethodID(entrycls.obj(), "id", "()J");
  texture_id_ = (int64_t)env->CallLongMethod(texture_entry_.obj(), get_id);

  // var surface_texture = texture_entry_.surfaceTexture();
  jmethodID surface_texture_id = env->GetMethodID(entrycls.obj(), "surfaceTexture", "()Landroid/graphics/SurfaceTexture;");
  webrtc::ScopedJavaLocalRef<jobject> surface_texture(env, env->CallObjectMethod(texture_entry_.obj(), surface_texture_id));

  // egl_renderer_ = new EglRenderer("SoraRenderer::Sink");
  auto renderercls = webrtc::GetClass(env, "org/webrtc/EglRenderer");
  jmethodID renderer_ctor_id = env->GetMethodID(renderercls.obj(), "<init>", "(Ljava/lang/String;)V");
  webrtc::ScopedJavaLocalRef<jobject> egl_renderer(env, env->NewObject(renderercls.obj(), renderer_ctor_id, env->NewStringUTF("SoraRenderer::Sink")));
  egl_renderer_ = egl_renderer;

  // // var egl_context = EglUtil.getRootEglBaseContext();
  // auto utilcls = webrtc::GetClass(env, "jp/shiguredo/sora_flutter_sdk/EglUtil");
  // jmethodID get_context_id = env->GetStaticMethodID(utilcls.obj(), "getRootEglBaseContext", "()Lorg/webrtc/EglBase$Context;");
  // webrtc::ScopedJavaLocalRef<jobject> egl_context(env, env->CallStaticObjectMethod(utilcls.obj(), get_context_id));

  // var config = EglBase.CONFIG_PLAIN;
  auto basecls = webrtc::GetClass(env, "org/webrtc/EglBase");
  jfieldID config_plain_id = env->GetStaticFieldID(basecls.obj(), "CONFIG_PLAIN", "[I");
  webrtc::ScopedJavaLocalRef<jobject> config(env, env->GetStaticObjectField(basecls.obj(), config_plain_id));

  // var drawer = new GlRectDrawer();
  auto drawercls = webrtc::GetClass(env, "org/webrtc/GlRectDrawer");
  jmethodID drawer_ctor_id = env->GetMethodID(drawercls.obj(), "<init>", "()V");
  webrtc::ScopedJavaLocalRef<jobject> drawer(env, env->NewObject(drawercls.obj(), drawer_ctor_id));

  // egl_renderer_.init(null, config, drawer);
  jmethodID renderer_init_id = env->GetMethodID(renderercls.obj(), "init", "(Lorg/webrtc/EglBase$Context;[ILorg/webrtc/RendererCommon$GlDrawer;)V");
  //env->CallVoidMethod(egl_renderer_.obj(), renderer_init_id, egl_context.obj(), config.obj(), drawer.obj());
  env->CallVoidMethod(egl_renderer_.obj(), renderer_init_id, nullptr, config.obj(), drawer.obj());

  // egl_renderer_.createEglSurface(surface_texture);
  jmethodID create_egl_surface_id = env->GetMethodID(renderercls.obj(), "createEglSurface", "(Landroid/graphics/SurfaceTexture;)V");
  env->CallVoidMethod(egl_renderer_.obj(), create_egl_surface_id, surface_texture.obj());
#elif defined(_WIN32)
  texture_id_ = texture_registrar_->RegisterTexture(texture_.get());
#elif defined(__APPLE__)
  pixel_buffer_ = NULL;
  texture_id_ = [texture_registrar_ registerTexture: texture_];
#elif defined(__linux__)
  fl_texture_registrar_register_texture(texture_registrar_, texture_.get());
  texture_id_ = reinterpret_cast<int64_t>(texture_.get());
#endif

  track_->AddOrUpdateSink(this, rtc::VideoSinkWants());
}
SoraRenderer::Sink::~Sink() {
  RTC_LOG(LS_INFO) << "[" << (void*)this << "] Sink::~Sink";
  track_->RemoveSink(this);
#if defined(__ANDROID__)
  auto env = env_;
  // egl_renderer_.release();
  // texture_entry_.release();
  webrtc::ScopedJavaLocalRef<jclass> renderercls(env, env->GetObjectClass(egl_renderer_.obj()));
  jmethodID renderer_release_id = env->GetMethodID(renderercls.obj(), "release", "()V");
  env->CallVoidMethod(egl_renderer_.obj(), renderer_release_id);
  RunOnMainThread(env, [this](JNIEnv* env) {
    webrtc::ScopedJavaLocalRef<jclass> entrycls(env, env->GetObjectClass(texture_entry_.obj()));
    jmethodID entry_release_id = env->GetMethodID(entrycls.obj(), "release", "()V");
    env->CallVoidMethod(texture_entry_.obj(), entry_release_id);
  });
#elif defined(__APPLE__)
    [texture_registrar_ unregisterTexture: texture_id_];
    CVPixelBufferRelease(pixel_buffer_);
#endif
}

int64_t SoraRenderer::Sink::GetTextureID() const {
  return texture_id_;
}

void SoraRenderer::Sink::OnFrame(const webrtc::VideoFrame& frame) {
  //RTC_LOG(LS_INFO) << "[" << (void*)this << "] Sink::OnFrame";
  {
    std::lock_guard<std::mutex> guard(mutex_);
    if (frame_ == nullptr) {
      frame_.reset(new webrtc::VideoFrame(frame));
    } else {
      *frame_ = frame;
    }
  }
#if defined(__ANDROID__)
  if (frame_->video_frame_buffer()->type() == webrtc::VideoFrameBuffer::Type::kNative) {
    frame_->set_video_frame_buffer(frame_->video_frame_buffer()->ToI420());
  }

  auto env = webrtc::AttachCurrentThreadIfNeeded();

  if (width_ != frame.width() || height_ != frame.height()) {
    // var surface_texture = texture_entry_.surfaceTexture();
    // surface_texture.setDefaultBufferSize(frame.width(), frame.height());
    webrtc::ScopedJavaLocalRef<jclass> entrycls(env, env->GetObjectClass(texture_entry_.obj()));
    jmethodID surface_texture_id = env->GetMethodID(entrycls.obj(), "surfaceTexture", "()Landroid/graphics/SurfaceTexture;");
    webrtc::ScopedJavaLocalRef<jobject> surface_texture(env, env->CallObjectMethod(texture_entry_.obj(), surface_texture_id));
    webrtc::ScopedJavaLocalRef<jclass> surfcls(env, env->GetObjectClass(surface_texture.obj()));
    jmethodID set_size_id = env->GetMethodID(surfcls.obj(), "setDefaultBufferSize", "(II)V");
    env->CallVoidMethod(surface_texture.obj(), set_size_id, frame.width(), frame.height());
    width_ = frame.width();
    height_ = frame.height();
  }

  // egl_renderer_.onFrame(frame);
  webrtc::ScopedJavaLocalRef<jobject> jframe = webrtc::NativeToJavaVideoFrame(env, *frame_);
  webrtc::ScopedJavaLocalRef<jclass> renderercls(env, env->GetObjectClass(egl_renderer_.obj()));
  jmethodID on_frame_id = env->GetMethodID(renderercls.obj(), "onFrame", "(Lorg/webrtc/VideoFrame;)V");
  env->CallVoidMethod(egl_renderer_.obj(), on_frame_id, jframe.obj());
#elif defined(_WIN32)
  texture_registrar_->MarkTextureFrameAvailable(texture_id_);
#elif defined(__APPLE__)
  [texture_registrar_ textureFrameAvailable: texture_id_];
#elif defined(__linux__)
  fl_texture_registrar_mark_texture_frame_available(texture_registrar_, texture_.get());
#endif
}

#if defined(__ANDROID__)
SoraRenderer::SoraRenderer(JNIEnv* env, jobject texture_registrar)
#elif defined(_WIN32)
SoraRenderer::SoraRenderer(flutter::TextureRegistrar* texture_registrar)
#elif defined(__APPLE__)
SoraRenderer::SoraRenderer(id<FlutterTextureRegistry> texture_registrar)
#elif defined(__linux__)
SoraRenderer::SoraRenderer(FlTextureRegistrar* texture_registrar)
#endif
#if defined(__ANDROID__)
: texture_registrar_(env, webrtc::JavaParamRef<jobject>(texture_registrar))
, env_(env)
#else
: texture_registrar_(texture_registrar)
#endif
{
}

int64_t SoraRenderer::AddTrack(webrtc::VideoTrackInterface* track) {
  RTC_LOG(LS_INFO) << "SoraRenderer::AddTrack";
#if defined(__ANDROID__)
  std::unique_ptr<Sink> sink(new Sink(track, env_, texture_registrar_.obj()));
#else
  std::unique_ptr<Sink> sink(new Sink(track, texture_registrar_));
#endif
  Sink* p = sink.get();
  sinks_.push_back(std::make_pair(track, std::move(sink)));
  return p->GetTextureID();
}

int64_t SoraRenderer::RemoveTrack(webrtc::VideoTrackInterface* track) {
  RTC_LOG(LS_INFO) << "SoraRenderer::RemoveTrack";
  auto f = [track](const VideoSinkVector::value_type& sink) {
    return sink.first == track;
  };
  auto it = std::find_if(sinks_.begin(), sinks_.end(), f);
  if (it == sinks_.end()) {
    return 0;
  }
  auto texture_id = it->second->GetTextureID();
  sinks_.erase(std::remove_if(sinks_.begin(), sinks_.end(), f), sinks_.end());
  return texture_id;
}

}  // namespace sora_flutter_sdk