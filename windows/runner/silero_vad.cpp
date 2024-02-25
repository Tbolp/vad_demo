#ifdef _WIN32
#define MODULEEXPORT extern "C" __declspec(dllexport)
#else
#define MODULEEXPORT extern "C" __attribute__((visibility("default")))
#endif

#include <cassert>
#include "net.h"

struct SileroVad {
  static SileroVad* create(const char* param,
                           int32_t len1,
                           const char* model,
                           int32_t len2) {
    auto ins = new SileroVad;
    auto ret = ins->m_net.load_param_mem(param);
    if (ret != 0) {
      delete ins;
      return nullptr;
    }
    ins->m_model = ncnn::Mat(len2);
    memcpy(ins->m_model.data, model, len2);
    ins->m_net.load_model((const unsigned char*)ins->m_model.data);
    return ins;
  }

  int run(const uint8_t* data, int32_t len) {
    assert(len == 1024);
    ncnn::Mat in(len >> 1, 1);
    for (int32_t i = 0; i < len >> 1; ++i) {
      int16_t tmp = data[2 * i] | data[2 * i + 1] << 8;
      in[i] = (float)tmp / 32768.0f;
    }
    auto ex = m_net.create_extractor();
    ex.input("input", in);
    ex.input("c", m_c);
    ex.input("h", m_h);
    ncnn::Mat out;
    auto ret = ex.extract("output", out);
    assert(ret == 0);
    ret = ex.extract("cn", m_c);
    assert(ret == 0);
    m_c = m_c.reshape(64, 2, 1);
    ret = ex.extract("hn", m_h);
    assert(ret == 0);
    m_h = m_h.reshape(64, 2, 1);
    auto result = *(float*)out.data;
    if (m_speaking) {
      if (result > m_therold) {
      } else {
        m_silence_count++;
        if (m_silence_count > m_silence_therold) {
          m_speaking = false;
        }
      }
    } else {
      if (result > m_therold) {
        m_speaking = true;
      } else {
        m_clear_count++;
        if (m_clear_count > m_clear_therold) {
          m_clear_count = 0;
          _clear();
        }
      }
    }
    return m_speaking ? 1 : 0;
  }

  void _clear() {
    m_c.fill(0);
    m_h.fill(0);
  }

  ncnn::Net m_net;
  ncnn::Mat m_model;
  bool m_speaking = false;
  float m_therold = 0.5f;
  int m_silence_count = 0;
  int m_silence_therold = 3;
  int m_clear_count = 0;
  int m_clear_therold = 5;
  ncnn::Mat m_c = {64, 2, 1};
  ncnn::Mat m_h = {64, 2, 1};
};

MODULEEXPORT int64_t create(const unsigned char* param,
                            int32_t len1,
                            const unsigned char* model,
                            int32_t len2) {
  auto ins =
      SileroVad::create((const char*)param, len1, (const char*)model, len2);
  return (int64_t)ins;
}

MODULEEXPORT int32_t run(int64_t handle, const uint8_t* data, int32_t len) {
  auto ins = (SileroVad*)handle;
  return ins->run(data, len);
}

MODULEEXPORT void destroy(int64_t handle) {
  auto ins = (SileroVad*)handle;
  delete ins;
}
